# frozen_string_literal: true

module Kracken
  module JsonApi
    module Validation
      module Conflicatable
        class ConflictValidator < ActiveRecord::Validations::UniquenessValidator
          def validate_each(record, attribute, value)
            record.clear_conflicts(attribute)
            error_set = super
            record.mark_conflicts(attribute) if error_set
            error_set
          end
        end

        module Macros
          def conflicts_on(*attr_names)
            validates_with ConflictValidator, _merge_attributes(attr_names)
          end
        end

        def self.included(klass)
          klass.extend Macros
        end

        def conflict_attrs
          @_conflict_attrs ||= Set.new
        end

        def mark_conflicts(*attrs)
          conflict_attrs.merge(attrs.flatten)
        end

        def clear_conflicts(attr = nil, *attrs)
          if attr.nil?
            conflict_attrs.clear
          else
            conflict_attrs.delete(attr).subtract(attrs)
          end
        end

        def conflicts?(attr = nil)
          if attr.blank?
            !conflict_attrs.empty?
          else
            conflict_attrs.include?(attr)
          end
        end
      end
    end
  end
end
