unless String.method_defined?(:constant?)
  class String
    def constant?
      names = self.split('::')
      names.shift if names.empty? || names.first.empty?
      constant = Object
      names.all? do |name|
        constant = constant.const_get(name)
      end
    rescue NameError
      false
    end
  end
end
