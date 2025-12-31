module Admin
  class SettingsController < BaseController
    def show
      @settings = Setting.all_with_defaults
    end

    def update
      changed_settings = {}

      settings_params.each do |key, value|
        old_value = Setting.get(key)
        Setting.set(key, value)
        new_value = Setting.get(key)

        if old_value.to_s != new_value.to_s
          changed_settings[key] = { from: old_value, to: new_value }
        end
      end

      if changed_settings.any?
        AuditLog.log(
          action: 'settings_updated',
          user: current_admin_user,
          metadata: { changes: changed_settings },
          request: request
        )
      end

      flash[:notice] = 'Settings updated successfully.'
      redirect_to admin_settings_path
    end

    private

    def settings_params
      params.require(:settings).permit(Setting::DEFAULTS.keys)
    end
  end
end
