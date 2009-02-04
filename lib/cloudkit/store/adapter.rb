module CloudKit

  # A common interface for pluggable storage adapters
  class Adapter
    include CloudKit::URIHelpers
    include CloudKit::ResponseHelpers

    # TODO extract from SQLAdapter - in progress...

    # Clear all contents of the store. Used mostly for testing.
    def reset!
    end

    # Return a list of resource URIs for the given collection URI. Sorted by
    # Last-Modified date in descending order.
    def resource_collection(uri, options)
    end

    # Return a collection of URIs for all versions of a resource including the
    #current version. Sorted by Last-Modified date in descending order.
    def version_collection(uri, options)
    end

    # Return a list of URIs for all resources matching the list of key value
    # pairs provided in the options arg.
    def view(uri, options)
    end
  end
end
