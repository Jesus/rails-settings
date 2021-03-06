module RailsSettings
  module Base
    def self.included(base)
      base.class_eval do
        has_many :setting_objects,
                 :as         => :target,
                 :autosave   => true,
                 :dependent  => :delete_all,
                 :class_name => "RailsSettings::SettingObject"

        def settings(var)
          raise ArgumentError unless var.is_a?(Symbol)
          raise ArgumentError.new("Unknown key: #{var}") unless self.class.setting_keys[var]

          fetch_settings_record(var)
            .becomes(self.class.setting_keys[var][:class_name].constantize)
        end

        def settings=(value)
          if value.nil?
            setting_objects.each(&:mark_for_destruction)
          else
            raise ArgumentError
          end
        end

        def settings?(var=nil)
          if var.nil?
            setting_objects.any? { |setting_object| !setting_object.marked_for_destruction? && setting_object.value.present? }
          else
            settings(var).value.present?
          end
        end

        def to_settings_hash
          Hash[self.class.setting_keys.map do |key, options|
            [key, options[:default_value].merge(settings(key.to_sym).value)]
          end]
        end

        private

        def fetch_settings_record(var)
          find_settings_record(var) or build_settings_record(var)
        end

        def find_settings_record(var)
          setting_objects.detect { |s| s.var == var.to_s }
        end

        def build_settings_record(var)
          if RailsSettings.can_protect_attributes?
            setting_objects.build({ :var => var.to_s }, :without_protection => true)
          else
            setting_objects.build(:var => var.to_s, :target => self)
          end
        end
      end
    end
  end
end
