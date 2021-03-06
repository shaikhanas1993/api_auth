module ApiAuth
  module RequestDrivers # :nodoc:
    class HttpRequest # :nodoc:
      include ApiAuth::Helpers

      def initialize(request)
        @request = request
      end

      def set_auth_header(header)
        @request['Authorization'] = header
        @request
      end

      def calculated_hash
        sha256_base64digest(body)
      end

      def populate_content_hash
        return unless %w[POST PUT].include?(http_method)

        @request['X-Authorization-Content-SHA256'] = calculated_hash
      end

      def content_hash_mismatch?
        if %w[POST PUT].include?(http_method)
          calculated_hash != content_hash
        else
          false
        end
      end

      def http_method
        @request.verb.to_s.upcase
      end

      def content_type
        find_header(%w[CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE])
      end

      def content_hash
        find_header(%w[X-AUTHORIZATION-CONTENT-SHA256])
      end

      def original_uri
        find_header(%w[X-ORIGINAL-URI X_ORIGINAL_URI HTTP_X_ORIGINAL_URI])
      end

      def request_uri
        @request.uri.request_uri
      end

      def set_date
        @request['Date'] = Time.now.utc.httpdate
      end

      def timestamp
        find_header(%w[DATE HTTP_DATE])
      end

      def authorization_header
        find_header %w[Authorization AUTHORIZATION HTTP_AUTHORIZATION]
      end

      def body
        if body_source.respond_to?(:read)
          result = body_source.read
          body_source.rewind
          result
        else
          body_source.to_s
        end
      end

      def fetch_headers
        capitalize_keys @request.headers.to_h
      end

      private

      def find_header(keys)
        keys.map { |key| @request[key] }.compact.first
      end

      def body_source
        body = @request.body

        if defined?(::HTTP::Request::Body)
          body.respond_to?(:source) ? body.source : body.instance_variable_get(:@body)
        else
          body
        end
      end
    end
  end
end
