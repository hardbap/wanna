class WannaScaffoldGenerator < Rails::Generator::NamedBase

  default_options :skip_timestamps => false,
                  :skip_migration  => false,
                  :skip_factory    => false,
                  :add_helper      => false,
                  :functional_test => false

  attr_reader :controller_name,
              :controller_class_path,
              :controller_file_path,
              :controller_class_nesting,
              :controller_class_nesting_depth,
              :controller_class_name,
              :controller_underscore_name,
              :controller_singular_name,
              :controller_plural_name

  alias_method :controller_file_name,  :controller_underscore_name
  alias_method :controller_table_name, :controller_plural_name

  def initialize(runtime_args, runtime_options = {})
    super

    if @name == @name.pluralize && !options[:force_plural]
      logger.warning "Plural version of the model detected, using singularized version.  Override with --force-plural."
      @name = @name.singularize
    end

    @controller_name = @name.pluralize

    base_name, @controller_class_path, @controller_file_path, @controller_class_nesting, @controller_class_nesting_depth = extract_modules(@controller_name)
    @controller_class_name_without_nesting, @controller_underscore_name, @controller_plural_name = inflect_names(base_name)
    @controller_singular_name = base_name.singularize

    if @controller_class_nesting.empty?
      @controller_class_name = @controller_class_name_without_nesting
    else
      @controller_class_name =
        "#{@controller_class_nesting}::#{@controller_class_name_without_nesting}"
    end
  end

  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions(controller_class_path,
        "#{controller_class_name}Controller", "#{controller_class_name}Helper")
      m.class_collisions(class_path, "#{class_name}")

      # Controller, helper, views, and test directories.
      m.directory(File.join('app/models', class_path))
      m.directory(File.join('app/controllers', controller_class_path))

      m.directory(File.join('app/views', controller_class_path, controller_file_name))

      m.directory(File.join('test/unit', class_path))

      for view in scaffold_views
        m.template(
          "view/#{view}.html.erb",
          File.join('app/views', controller_class_path, controller_file_name, "#{view}.html.erb")
        )
      end

      m.template(
        'controller.rb', File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb")
      )

      if options[:functional_test]
        m.directory(File.join('test/functional', controller_class_path))
        m.template("functional_test/shoulda_controller.rb",
                   File.join('test/functional', controller_class_path,
                             "#{controller_file_name}_controller_test.rb"))
      end

      if options[:add_helper]
        m.directory(File.join('app/helpers', controller_class_path))
        m.directory(File.join('test/unit/helpers', class_path))
        m.template('helper.rb',
                   File.join('app/helpers', controller_class_path,
                             "#{controller_file_name}_helper.rb"))
        m.template('helper_test.rb',
                   File.join('test/unit/helpers', class_path,
                             "#{controller_file_name}_helper_test.rb"))
      end

      m.route_resources controller_file_name

      m.dependency 'wanna_model', [name] + @args, :collision => :skip
    end
  end

  protected

  # Override with your own usage banner.
  def banner
    "Usage: #{$0} wanna_scaffold ModelName [field:type, field:type]"
  end

  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    scaffold_options.each do |key, val|
      opt.on("--#{key}", val) { |v| options[key.underscore.to_sym] = v }
    end
  end

  def scaffold_views
    %w{ index show new edit _form }
  end

  def model_name
    class_name.demodulize
  end

  def scaffold_options
    { 'skip-timestamps' => "Don't add timestamps to the migration file for this model",
      'skip-migration' => "Don't generate a migration file for this model",
      'skip-factory' => "Don't generation a factory file for this model",
      'add-helper' => "Generate a helper for this controller",
      'functional-test' => "Generate a functional test for this controller" }

  end
end
