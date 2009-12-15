module MTI
  def make_attr_class
    sym = self.class.to_s.underscore
    cl = self.class.to_s + "Attribute"
    class_def = <<EOT
class #{cl} < ActiveRecord::Base
  belongs_to :#{sym}
end
EOT
    eval(class_def)
  end

  attr_accessor :attr_class
  def load_extra_attribute_class
    make_attr_class
    sym = self.class.to_s.underscore + "_attribute"
    self.class.has_one(sym.to_sym, {:dependent => :destroy})
    cl = self.class.to_s + "Attribute"

    @attr_class = self.send(sym)
    if @attr_class.nil?
      self.send(sym+"=", eval(cl).new)
      @attr_class = self.send(sym)
    end
  rescue ActiveRecord::StatementInvalid
    puts "Your model is not valid for MTI, please create #{eval(cl).table_name}"
    @attr_class = nil
  end

  def method_missing(sym, *args, &block)
    if @attr_class.respond_to? sym
      return @attr_class.send(sym, *args, &block)
    end
    super
  end

  def after_initialize
    load_extra_attribute_class
  end
end
