module CloudKit

  # A common interface for pluggable storage adapters
  class Adapter
    include CloudKit::URIHelpers
    include CloudKit::ResponseHelpers

    # TODO extract from SQLAdapter - in progress...

    # Clear all contents of the store. Used mostly for testing.
    def reset!
    end

    # Return the resource for the given URI. Return 404 if not found or if
    # protected and unauthorized, 410 if authorized but deleted.
    def resource(uri, options)
    end

    # Return a specific version of a resource.
    def resource_version(uri, options)
    end

    # Return all documents and their associated metadata for the given
    # collection URI.
    def resolved_resource_collection(uri, options)
    end

    # Return a list of resource URIs for the given collection URI. Sorted by
    # Last-Modified date in descending order.
    def resource_collection(uri, options)
    end

    # Return a collection of URIs for all versions of a resource including the
    #current version. Sorted by Last-Modified date in descending order.
    def version_collection(uri, options)
    end

    # Return all document versions and their associated metadata for a given
    # resource including the current version. Sorted by Last-Modified date in
    # descending order.
    def resolved_version_collection(uri, options)
    end

    # Return a list of URIs for all resources matching the list of key value
    # pairs provided in the options arg.
    def view(uri, options)
    end
  end
end
