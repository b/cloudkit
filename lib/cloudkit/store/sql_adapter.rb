module CloudKit

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
    
    def view(uri, options)
      result = @db[collection_type(uri)].
        select(:uri).
        filter(options.excluding(:offset, :limit))
      bundle_collection_result(uri, options, result)
    end
    
    def bundle_collection_result(uri, options, result)
      total  = result.count
      offset = options[:offset].try(:to_i) || 0
      max    = options[:limit] ? offset + options[:limit].to_i : total
      list   = result.all[offset...max].map{|r| r[:uri]}
      json   = uri_list(list, total, offset)
      last_modified = result.first[:last_modified] if result.any?
      response(200, json, build_etag(json), last_modified)
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
