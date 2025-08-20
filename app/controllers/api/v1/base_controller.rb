module Api
  module V1
    class BaseController < ApplicationController
      include ApiHelpers
      before_action :set_default_format
      before_action :authenticate_user!

      private

      def authenticate_user!
        unless current_user
          render json: { error: 'Unauthorized' }, status: :unauthorized
          return
        end
      end

      def set_default_format
            request.format = 'json'
      end
    end
  end
end
