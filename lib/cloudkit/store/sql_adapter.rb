module CloudKit

  # TODO - This is too coarse-grained right now. It needs to expose only
  # storage methods and leave the rest of the logic to the Store itself.
  # Then, adapter implementations have less to implement.
  
  # Adapts a CloudKit::Store to a SQL backend.
  class SQLAdapter < Adapter

    # Initialize a new SQL backend. Defaults to in-memory SQLite.
    def initialize(uri=nil, options={})
      @db = uri ? Sequel.connect(uri, options) : Sequel.sqlite
      # TODO accept views as part of a store, then initialize them here
      initialize_storage
    end

    def reset!
      @db.schema.keys.each do |table|
        @db[table.gsub('`','').to_sym].delete
      end
    end
    
    def resource(uri, options)
      result = @db[CLOUDKIT_STORE].
        select(:content, :etag, :last_modified, :deleted).
        filter(options.merge!(:uri => uri))
      if result.any?
        result = result.first
        return status_410 if result[:deleted]
        return response(200, result[:content], result[:etag], result[:last_modified])
      end
      status_404
    end
    
    def resource_version(uri, options)
      result = @db[CLOUDKIT_STORE].
        select(:content, :etag, :last_modified).
        filter(options.merge(:uri => uri))
      return status_404 unless result.any?
      result = result.first
      response(200, result[:content], result[:etag], result[:last_modified])
    end
    
    def resolved_resource_collection(uri, options)
      result = @db[CLOUDKIT_STORE].
        filter(options.excluding(:offset, :limit).merge(:deleted => false)).
        filter(:collection_reference => collection_uri_fragment(uri)).
        filter('resource_reference = uri').
        reverse_order(:id)
      bundle_resolved_collection_result(uri, options, result)
    end
    
    def resource_collection(uri, options)
      result = @db[CLOUDKIT_STORE].
        select(:uri, :last_modified).
        filter(options.excluding(:offset, :limit).merge(:deleted => false)).
        filter(:collection_reference => collection_uri_fragment(uri)).
        filter('resource_reference = uri').
        reverse_order(:id)
      bundle_collection_result(uri, options, result)
    end
    
    def version_collection(uri, options)
      found = @db[CLOUDKIT_STORE].
        select(:uri).
        filter(options.excluding(:offset, :limit).merge(
          :uri => current_resource_uri(uri)))
      return status_404 unless found.any?
      result = @db[CLOUDKIT_STORE].
        select(:uri, :last_modified).
        filter(:resource_reference => current_resource_uri(uri)).
        filter(options.excluding(:offset, :limit).merge(:deleted => false)).
        reverse_order(:id)
      bundle_collection_result(uri, options, result)
    end
    
    def resolved_version_collection(uri, options)
      found = @db[CLOUDKIT_STORE].
        select(:uri).
        filter(options.excluding(:offset, :limit).merge(
          :uri => current_resource_uri(uri)))
      return status_404 unless found.any?
      result = @db[CLOUDKIT_STORE].
        filter(:resource_reference => current_resource_uri(uri)).
        filter(options.excluding(:offset, :limit).merge(:deleted => false)).
        reverse_order(:id)
      bundle_resolved_collection_result(uri, options, result)
    end
    
    def view(uri, options)
      result = @db[collection_type(uri)].
        select(:uri).
        filter(options.excluding(:offset, :limit))
      bundle_collection_result(uri, options, result)
    end
    
    # Bundle a collection of results as a list of URIs for the response.
    def bundle_collection_result(uri, options, result)
      total  = result.count
      offset = options[:offset].try(:to_i) || 0
      max    = options[:limit] ? offset + options[:limit].to_i : total
      list   = result.all[offset...max].map{|r| r[:uri]}
      json   = uri_list(list, total, offset)
      last_modified = result.first[:last_modified] if result.any?
      response(200, json, build_etag(json), last_modified)
    end
    
    # Bundle a collection of results as a list of documents and the associated
    # metadata (last_modified, uri, etag) that would have accompanied a response
    # to their singular request.
    def bundle_resolved_collection_result(uri, options, result)
      total  = result.count
      offset = options[:offset].try(:to_i) || 0
      max    = options[:limit] ? offset + options[:limit].to_i : total
      list   = result.all[offset...max]
      json   = resource_list(list, total, offset)
      last_modified = result.first[:last_modified] if result.any?
      response(200, json, build_etag(json), last_modified)
    end

    # Generate a JSON document list.
    def resource_list(list, total, offset)
      results = []
      list.each do |resource|
        results << {
          :uri           => resource[:uri],
          :etag          => resource[:etag],
          :last_modified => resource[:last_modified],
          :document      => resource[:content]}
      end
      JSON.generate(:total => total, :offset => offset, :documents => results)
    end

    # method_missing is a placeholder for future interface extraction into
    # CloudKit::Adapter.
    def method_missing(method, *args, &block)
      @db.send(method, *args, &block)
    end

    protected

    # Initialize the HTTP-oriented storage if it does not exist.
    def initialize_storage
      @db.create_table CLOUDKIT_STORE do
        primary_key :id
        varchar     :uri, :unique => true
        varchar     :etag
        varchar     :collection_reference
        varchar     :resource_reference
        varchar     :last_modified
        varchar     :remote_user
        text        :content
        boolean     :deleted, :default => false
      end unless @db.table_exists?(CLOUDKIT_STORE)
    end
  end
end
