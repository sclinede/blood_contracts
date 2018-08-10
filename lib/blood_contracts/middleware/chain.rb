module BloodContracts
  module Middleware
    class Chain
      include Enumerable
      attr_reader :entries

      def each(&block)
        entries.each(&block)
      end

      def initialize
        @entries = []
        yield self if block_given?
      end

      def remove(klass)
        entries.delete_if { |entry| entry.klass == klass }
      end

      def add(klass, *args)
        remove(klass) if exists?(klass)
        entries << Entry.new(klass, *args)
      end

      def prepend(klass, *args)
        remove(klass) if exists?(klass)
        entries.insert(0, Entry.new(klass, *args))
      end

      def insert_before(oldklass, newklass, *args)
        i = entries.index { |entry| entry.klass == newklass }
        new_entry = i.nil? ? Entry.new(newklass, *args) : entries.delete_at(i)
        i = entries.index { |entry| entry.klass == oldklass } || 0
        entries.insert(i, new_entry)
      end

      # rubocop:disable Metrics/AbcSize
      def insert_after(oldklass, newklass, *args)
        i = entries.index { |entry| entry.klass == newklass }
        new_entry = i.nil? ? Entry.new(newklass, *args) : entries.delete_at(i)
        i = entries.index { |entry| entry.klass == oldklass }
        i ||= entries.count - 1
        entries.insert(i + 1, new_entry)
      end
      # rubocop:enable Metrics/AbcSize

      def index_of(klass)
        entries.index { |entry| entry.klass == klass }
      end

      def exists?(klass)
        any? { |entry| entry.klass == klass }
      end

      def retrieve
        map(&:make_new)
      end

      def clear
        entries.clear
      end

      def invoke(*args)
        chain = retrieve.dup
        traverse_chain = lambda do
          chain.shift.call(*args, &traverse_chain) unless chain.empty?
        end
        traverse_chain.call
      end
    end

    class Entry
      attr_reader :klass

      def initialize(klass, *args)
        @klass = klass
        @args  = args
      end

      def make_new
        @klass.new(*@args)
      end
    end
  end
end
