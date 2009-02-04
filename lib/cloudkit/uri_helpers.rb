module CloudKit::URIHelpers
  # TODO make this a class instead of an instance after the Adapter extraction
  # is complete. Cache parsed arrays for requests.
  
  # Build a response containing the allowed methods for a given URI.
  def options(uri)
    methods = methods_for_uri(uri)
    allow(methods)
  end

  # Return a list of allowed methods for a given URI.
  def methods_for_uri(uri)
    return meta_methods                         if meta_uri?(uri)
    return resource_collection_methods          if resource_collection_uri?(uri)
    return resolved_resource_collection_methods if resolved_resource_collection_uri?(uri)
    return resource_methods                     if resource_uri?(uri)
    return version_collection_methods           if version_collection_uri?(uri)
    return resolved_version_collection_methods  if resolved_version_collection_uri?(uri)
    return resource_version_methods             if resource_version_uri?(uri)
  end

  # Return the list of methods allowed for the cloudkit-meta URI.
  def meta_methods
    @meta_methods ||= http_methods.excluding('POST', 'PUT', 'DELETE')
  end

  # Return the list of methods allowed for a resource collection.
  def resource_collection_methods
    @resource_collection_methods ||= http_methods.excluding('PUT', 'DELETE')
  end

  # Return the list of methods allowed on a resolved resource collection.
  def resolved_resource_collection_methods
    @resolved_resource_collection_methods ||= http_methods.excluding('POST', 'PUT', 'DELETE')
  end

  # Return the list of methods allowed on an individual resource.
  def resource_methods
    @resource_methods ||= http_methods.excluding('POST')
  end

  # Return the list of methods allowed on a version history collection.
  def version_collection_methods
    @version_collection_methods ||= http_methods.excluding('POST', 'PUT', 'DELETE')
  end

  # Return the list of methods allowed on a resolved version history collection.
  def resolved_version_collection_methods
    @resolved_version_collection_methods ||= http_methods.excluding('POST', 'PUT', 'DELETE')
  end

  # Return the list of methods allowed on a resource version.
  def resource_version_methods
    @resource_version_methods ||= http_methods.excluding('POST', 'PUT', 'DELETE')
  end

  # Return true if this store implements a given HTTP method.
  def implements?(http_method)
    http_methods.include?(http_method.upcase)
  end

  # Return the list of HTTP methods supported by this Store.
  def http_methods
    ['GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'OPTIONS']
  end

  # Return the resource collection URI fragment.
  # Example: collection_uri_fragment('/foos/123') => '/foos
  def collection_uri_fragment(uri)
    "/#{uri_components(uri)[0]}" rescue nil
  end

  # Return the resource collection referenced by a URI.
  # Example: collection_type('/foos/123') => :foos
  def collection_type(uri)
    uri_components(uri)[0].to_sym rescue nil
  end

  # Return the URI for the current version of a resource.
  # Example: current_resource_uri('/foos/123/versions/abc') => '/foos/123'
  def current_resource_uri(uri)
    "/#{uri_components(uri)[0..1].join('/')}" rescue nil
  end

  # Splits a URI into its components
  def uri_components(uri)
    uri.split('/').reject{|x| x == '' || x == nil} rescue []
  end

  # Returns true if URI matches /cloudkit-meta
  def meta_uri?(uri)
    c = uri_components(uri)
    return c.size == 1 && c[0] == 'cloudkit-meta'
  end

  # Returns true if URI matches /{collection}
  def resource_collection_uri?(uri)
    c = uri_components(uri)
    return c.size == 1 && @collections.include?(c[0].to_sym)
  end

  # Returns true if URI matches /{collection}/_resolved
  def resolved_resource_collection_uri?(uri)
    c = uri_components(uri)
    return c.size == 2 && @collections.include?(c[0].to_sym) && c[1] == '_resolved'
  end

  # Returns true if URI matches /{collection}/{uuid}
  def resource_uri?(uri)
    c = uri_components(uri)
    return c.size == 2 && @collections.include?(c[0].to_sym) && c[1] != '_resolved'
  end

  # Returns true if URI matches /{collection}/{uuid}/versions
  def version_collection_uri?(uri)
    c = uri_components(uri)
    return c.size == 3 && @collections.include?(c[0].to_sym) && c[2] == 'versions'
  end

  # Returns true if URI matches /{collection}/{uuid}/versions/_resolved
  def resolved_version_collection_uri?(uri)
    c = uri_components(uri)
    return c.size == 4 && @collections.include?(c[0].to_sym) && c[2] == 'versions' && c[3] == '_resolved'
  end

  # Returns true if URI matches /{collection}/{uuid}/versions/{etag}
  def resource_version_uri?(uri)
    c = uri_components(uri)
    return c.size == 4 && @collections.include?(c[0].to_sym) && c[2] == 'versions' && c[3] != '_resolved'
  end

  # Returns true if URI matches /{view}
  def view_uri?(uri)
    c = uri_components(uri)
    return c.size == 1 && @views && @views.map{|v| v.name}.include?(c[0].to_sym)
  end
end