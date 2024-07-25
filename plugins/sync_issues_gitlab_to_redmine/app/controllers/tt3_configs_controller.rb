class Tt3ConfigsController < ApplicationController

  def index
    @tt3_configs = Tt3Configs.all
  end
end
