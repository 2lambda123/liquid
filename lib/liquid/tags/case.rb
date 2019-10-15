# frozen_string_literal: true

module Liquid
  class Case < Block
    Syntax     = /(#{QuotedFragment})/o
    WhenSyntax = /(#{QuotedFragment})(?:(?:\s+or\s+|\s*\,\s*)(#{QuotedFragment}.*))?/om

    attr_reader :blocks, :left

    def parse(tokens)
      @blocks = []

      if options =~ Syntax
        @left = Expression.parse(Regexp.last_match(1))
      else
        raise SyntaxError, options[:locale].t("errors.syntax.case")
      end

      body = BlockBody.new
      body = @blocks.last.attachment while parse_body(body, tokens)
    end

    def nodelist
      @blocks.map(&:attachment)
    end

    def unknown_tag(tag, markup, tokens)
      case tag
      when 'when'
        record_when_condition(markup)
      when 'else'
        record_else_condition(markup)
      else
        super
      end
    end

    def render_to_output_buffer(context, output)
      execute_else_block = true

      @blocks.each do |block|
        if block.else?
          block.attachment.render_to_output_buffer(context, output) if execute_else_block
        elsif block.evaluate(context)
          execute_else_block = false
          block.attachment.render_to_output_buffer(context, output)
        end
      end

      output
    end

    private

    def record_when_condition(markup)
      body = BlockBody.new

      while markup
        unless markup =~ WhenSyntax
          raise SyntaxError, options[:locale].t("errors.syntax.case_invalid_when")
        end

        markup = Regexp.last_match(2)

        block = Condition.new(@left, '==', Expression.parse(Regexp.last_match(1)))
        block.attach(body)
        @blocks << block
      end
    end

    def record_else_condition(markup)
      unless markup.strip.empty?
        raise SyntaxError, options[:locale].t("errors.syntax.case_invalid_else")
      end

      block = ElseCondition.new
      block.attach(BlockBody.new)
      @blocks << block
    end

    class ParseTreeVisitor < Liquid::ParseTreeVisitor
      def children
        [@node.left] + @node.blocks
      end
    end
  end

  Template.register_tag('case', Case)
end
