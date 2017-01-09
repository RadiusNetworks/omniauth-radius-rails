module Kracken
  module Controllers
    module JsonApiCompatible

      module MungeAndMirror
        # Wraps the data root in an Array, if it is not already an Array. This
        # will not wrap the value if the resource root is not present.
        def munge_resource_root!
          return unless params.key?(resource_type)
          # We don't want to munge a non-existent key
          params[resource_type] = Array.wrap(params[resource_type])
          munge_optional_id!
        end

      private

        def munge_chained_param_ids!
          return unless params[:id]
          params[:id] = params[:id].split(/,\s*/)
        end

        def can_munge_ids?
          (!params[:id].nil? && params[:id].size == 1) &&
            params[resource_type].size == 1
        end

        def munge_optional_id!
          return unless can_munge_ids?
          params[resource_type].first[:id] ||= params[:id].first
        end
      end

      module Macros
        def self.extended(klass)
          klass.instance_exec do
            include MungeAndMirror
          end
        end

        def resource_type(type = nil)
          if type
            alias_method "#{type}_root", :data_root
            @_resource_type = type.to_sym
          end
          @_resource_type ||= :data
        end

        def munge_resource_root!
          before_action :munge_resource_root!
        end

        def verify_scoped_resource(resource, options = {})
          name = "verify_scoped_#{resource}".to_sym
          relation = options.extract!(:as).fetch(:as, resource).to_s.pluralize
          scope = options.extract!(:scope).fetch(:scope, :current_user)
          resource_id = (resource_type == resource.to_sym) ? :id : "#{resource}_id"
          define_method(name) do
            param_ids = Array(params[resource_id])
            found_ids = self.send(scope)
                            .send(relation)
                            .where(id: param_ids)
                            .ids
                            .map(&:to_s)
            missing_ids = param_ids - found_ids
            unless missing_ids.empty?
              raise ResourceNotFound.new(resource, missing_ids)
            end
          end
          before_action name, options
        end

        def verify_required_params(options = {})
          before_action :verify_required_params!, options
        end
      end

      def self.included(base)
        base.instance_exec do
          extend Macros

          before_action :munge_chained_param_ids!
        end
      end

      module DataIntegrity
        # Scan each item in the data root and enforce it has an id set.
        def enforce_resource_ids!
          Array.wrap(data_root).each do |resource|
            resource.require(:id)
          end
        end

        # Check the provided params to make sure the root resource type key is set.
        # If the value for the key is an array, make sure all of the contained hashes
        # have an `id` set.
        def verify_required_params!
          return unless params.require(resource_type) && params[:id]
          if Array === data_root
            enforce_resource_ids!
          elsif params[:id].many?
            raise UnprocessableEntity,
                  "Single beacon object provided but multiple resources requested"
          end
        end
      end
      include DataIntegrity

      module VirtualAttributes
        # Grab the data root from the params.
        #
        # This will either be params[:data] or the custom resource type set on the
        # class.
        def data_root
          params[resource_type]
        end

        # Get the set resource type from the class
        def resource_type
          self.class.resource_type
        end
      end
      include VirtualAttributes

      def self.included(base)
        base.instance_exec do
          extend Macros

          before_action :munge_chained_param_ids!
          skip_before_action :verify_authenticity_token, raise: false

          if defined?(::ActiveRecord)
            rescue_from ::ActiveRecord::RecordNotFound do |error|
              # In order to use named captures we need to use an inline regex
              # on the LHS.
              #
              # Source: http://rubular.com/r/NoQ4SZMav4
              /Couldn't find( all)? (?<resource>\w+) with 'id'.?( \()?(?<ids>[,\s\w]+)\)?/ =~ error.message
              resource = resource.underscore.pluralize
              raise ResourceNotFound.new(resource, ids.strip)
            end
          end
        end
      end

    # Common Actions Necessary in JSON API controllers
    module_function

      # Wrap a block in an Active Record transaction
      #
      # The return value of the block is checked to see if it should be considered
      # successful. If the value is falsey the transaction is rolledback. If a
      # collection of ActiveRecord (or quacking) objects are returned they are
      # checked to make sure none have any errors.
      def in_transaction
        ActiveRecord::Base.transaction {
          memo = yield
          was_success = !!memo && Array(memo).all? { |t| t.errors.empty? }
          was_success or raise ActiveRecord::Rollback
        }
      end

      # Process parameters in the standard JSON API way.
      #
      # If there is no set `id`, the request was likely a `POST` / create action.
      # The params are mapped to the permitted params. Otherwise, index the data by
      # the supplied ids and transform all the values based on the provided
      # permitted params (for strong parameters).  Only objects whose `id`s match
      # the requested ids are returned.
      #
      # If the data was a Hash, then the single `permit_params` object is returned.
      # Or the tuple [`id`, `permitd_params`] respectively.
      def process_params(permitted_params)
        single_resource = Hash === data_root
        data = Array.wrap(data_root)
        mapping = if params[:id].blank?
                    data.map { |attrs| attrs.permit(permitted_params) }
                  else
                    data.index_by { |d| d[:id].to_s }
                      .transform_values { |attrs| attrs.permit(permitted_params) }
                      .slice(*params[:id])
                  end
        single_resource ? mapping.first : mapping
      end

    end
  end
end
