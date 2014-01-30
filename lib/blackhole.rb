require "blackhole/empty_black_hole"
require "blackhole/exceptions"
require "blackhole/version"

class BlackHole < ::BasicObject

=begin

- TODO: builder class which returns an BlockHole object with the configured with the passed settings
- TODO: configuration determines what is the default? Can be nil instead of EmptyBlackHole?
- TODO: builder class can also load data from external files, like yml?
- TODO: convert to proto? gem -> Convert any object to an prototype object, can overwrite everything

=end

  # TODO: possible to wrap around object, so can add methods / properties to any object?
  # create a new BlackHole object
  def initialize(imitate = EmptyBlackHole.instance)

    # TODO: only objects can be imitated? Should be able to store classes?
    if imitate.class == ::Class
      raise "Passed argument should be an instance, not a class"
    end

    # create new children hash
    # TODO: only instantiate when actually needed!
    @_nodes           = {}

    # store the imitated object
    @_imitated_object = imitate

    # update the case equality
    update_class_case_equality imitate

    # create the tracer
    # TODO: onyl instantiate when actually needed!
    setup_tracer

  end

  # get the imitated object
  def __getobj__

    @_imitated_object

  end

  # set the imitated object
  def __setobj__=(object)

    @_imitated_object = object

  end

  # the magic happens here
  def method_missing(name, *args, &block)

    puts "#{@_imitated_object.inspect} - #{name}: #{args.inspect}"

    # the object doesn't have any methods, so all methods called here are probably called on the imitate object
    # so when calling puts from here -> calles method_missing -> calls puts -> calls method missing -> stack overload

    # if target object has the property name
    # TODO: try until throws NoMethodError instead of respond_to?
    if @_imitated_object.respond_to?(name)

      # call the method on the imitated object and return the value
      return @_imitated_object.send(name, *args, &block)

    end

    # throw error if too many arguments are passed
    raise "Too many arguments passed: #{args.inspect}" if args.count > 1

    # check if the method is a setter
    if name[-1] == '='

      # set the value
      set_value(name, args[0])

    else

      # get the value
      return_value = get_value(name, block)

      # if the returned value is empty
      # TODO: only do this when configured: raise on empty return
      if return_value && return_value.__getobj__.instance_of?(EmptyBlackHole)

        # store the backtrace
        @_backtrace = ::BlackHole.send(:caller)

        # store the method called
        @_called_method_name = name

        # start the tracer
        @_trace.enable

      end

      # return the return value
      return_value

    end

  end

  # define is_a? method to determine of the object is a BlackHole object
  def is_a?(clazz)

    clazz == ::BlackHole || @_imitated_object.is_a?(clazz)

  end

  # kind_of? is the same as is_a?
  alias_method :kind_of?, :is_a?

  private

  # set the value in the nodes
  def set_value(name, value)

    #- when storing the passed blockhole object as the passed blockhole project:
    #  - when getting something from the blockhole, returns a blockhole object
    #  - when saving this object into the blockhole at another name, the setting is shared between 2 settings
    #
    #- when storing the value in the passed blockhole object in the new blockhole project:
    #  - when retrieving a blockhole setting and saving in another name, the setting isn't shared

    # TODO: different ways of setting the object? Copy the entire BlackHole or only the imitated_object value
    # when copying the entire object, single values can be shared between multiple settings
    # remove the last character from the name
    name = remove_last_character(name)

    # update the BlackHole when already exists
    if @_nodes.has_key? name

      # check if the passed node is a blackhole
      if value.is_a? ::BlackHole

        # store the other imitated object in the current node
        @_nodes[name].__setobj__ = value.__getobj__

      else

        # update the blockhole object
        @_nodes[name].__setobj__ = value

      end

    else

      # check if the passed node is a blackhole
      if value.is_a? ::BlackHole

        @_nodes[name] = get_node value.__getobj__

      else

        # get a new node and store it
        @_nodes[name] = get_node value

      end

    end

    # TODO: what to return??
    # return nil
    nil

  end

  # get the value from the stored nodes
  def get_value(name, block)

    # instantiate the return value
    return_value = nil

    # TODO: return the original BlackHole object OR return a copy / clone of the BlackHole object?
    # that way settings aren't shared and wont update the tree as soon as the first get request
    case

      # the key exists, return the value
      when @_nodes.has_key?(name)

        # return the Blackhole object
        return_value = @_nodes[name]

      # the key doesn't exist
      # TODO: this is a bit hacky, should be implemented in another way
      when name == :to_ary

        # return nil when calling to ary
        return_value = nil

      when name == :each

        # iteration!
        @_nodes.each do |name, value|

          # call the block
          block.call(name, value)

        end

        # TODO: change the return value to something else?
        return_value = nil

      # the name doesn't exist and is a getter
      else

        # get a new node with a with an empty Blockhole
        # store it among the nodes and make it the return value
        return_value = @_nodes[name] = get_node(EmptyBlackHole.instance)

    end

    # return the return value
    return_value

  end

  # method called by the tracepoint object
  # checks if the action after the return value is another blackhole
  def check_return_missing_method(tp)

    # puts tp.inspect

    # if the method_missing methood returned the value
    if @_method_missing_returned

      # disable the trace
      @_trace.disable

      # reset the method_missing flag
      @_method_missing_returned = nil

      # the method right after the return of the method_missing
      unless  tp.event == :call &&
          tp.defined_class == ::BlackHole &&
          tp.method_id == :method_missing

        # raise the exception with a custom backtrace
        raise empty_exception(@_backtrace, @_called_method_name)

      end

      # reset the called method name
      @_called_method_name = nil

      # reset the backtrace
      @_backtrace = nil

    else

      # listen the return event of the method_missing method
      if  tp.event == :return &&
          tp.defined_class == ::BlackHole &&
          tp.method_id == :method_missing

        # the return is now done of the method
        @_method_missing_returned = true

      end

    end

    # TODO: make an counter, that after 5? events -> should trigger NON returned error

  end

  # create an empty exception
  def empty_exception(backtrace, method)

    # create the exception
    e = BlackHoleError.new "undefined method `#{method}`."

    # set the backtrace
    e.set_backtrace backtrace

    # return the exception
    e

  end

  # instantiate a new tracepoint object
  def setup_tracer

    # TODO: maybe don't log all messages?
    @_trace = ::TracePoint.new() { |tp| check_return_missing_method(tp) }

  end

  # BlackHole extends BasicObject and doesn't have any bsaic methods
  # puts is here for debuggin purposes
  def puts(message)

    ::BlackHole.send(:puts, message)

  end

  # method for raising an exception
  def raise(exception)

    ::BlackHole.send(:raise, exception)

  end

  # update the case equality on the class of the parameter imitate
  # this way it also passes when compared with a BlackHole object
  def update_class_case_equality(imitate)

    # get the class of the object
    clazz = get_class imitate

    # update unless already updated?
    unless clazz.const_defined? :BLACKHOLE_CASE_EQUALITY_UPDATED

      # define the constant
      clazz.const_set :BLACKHOLE_CASE_EQUALITY_UPDATED, true

      # class evaluate
      clazz.class_eval do

        # the self. is important, because it is a class level operator
        def self.===(obj)

          if obj.is_a? ::BlackHole

            super obj.__getobj__

          else

            super obj

          end

        end

      end

    end

  end

  # get the class from the parameter object
  def get_class(object)

    # get the class
    if object.class == ::Class
      object
    else
      object.class
    end

  end

  # remove the last character from the symbol, return a symbol
  def remove_last_character(symbol)

    symbol[0..-2].to_sym

  end

  # get a new node, maybe introduce object pooling?
  def get_node(value)

    ::BlackHole.new(value)

  end

end
