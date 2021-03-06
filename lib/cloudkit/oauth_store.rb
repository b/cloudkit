module CloudKit

  # An OAuthStore is a thin abstraction around CloudKit::Store, providing
  # consistent collection names, and allowing automatic migrations in later
  # releases if needed.
  class OAuthStore
    @@store = nil

    # Initialize a Store for use with OAuth middleware. Load the static consumer
    # resource if it does not exist.
    def initialize(uri=nil)
      @@store = Store.new(
        :collections => [
          :cloudkit_oauth_nonces,
          :cloudkit_oauth_tokens,
          :cloudkit_oauth_request_tokens,
          :cloudkit_oauth_consumers],
        :adapter => SQLAdapter.new(uri)) unless @@store
      load_static_consumer
    end

    def get(uri, options={}) #:nodoc:
      @@store.get(uri, options)
    end

    def post(uri, options={}) #:nodoc:
      @@store.post(uri, options)
    end

    def put(uri, options={}) #:nodoc:
      @@store.put(uri, options)
    end

    def delete(uri, options={}) #:nodoc:
      @@store.delete(uri, options)
    end

    def reset! #:nodoc:
      @@store.reset!
    end

    # Return the version number for this store.
    def version; 1; end

    # Load the static consumer entity if it does not already exist.
    # See the OAuth Discovery spec for more info on static consumers.
    def load_static_consumer
      json = JSON.generate(:secret => '')
      @@store.put('/cloudkit_oauth_consumers/cloudkitconsumer', :json => json)
    end
  end
end
