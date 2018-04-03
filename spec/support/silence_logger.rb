module SilenceLogger
  def self.included(base)
    base.let(:stub_logger) { stub_everything }

    base.before do
      @logger = YARD::Logger.instance
      stub_logger.stubs(:enter_level).yields
      stub_logger.stubs(:capture).yields
      YARD::Logger.send :instance_variable_set, :@logger, stub_logger
    end

    base.after do
      YARD::Logger.send :instance_variable_set, :@logger, @logger
    end
  end
end
