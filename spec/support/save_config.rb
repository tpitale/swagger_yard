module SaveConfig
  def self.included(base)
    base.before do
      @config = SwaggerYard.config
      SwaggerYard.send :instance_variable_set, :@configuration, @config.dup
    end

    base.after do
      SwaggerYard.send :instance_variable_set, :@configuration, @config
    end
  end
end
