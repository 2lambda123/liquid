# frozen_string_literal: true

module Liquid
  class Raw < Block
    Syntax = /\A\s*\z/
    FullTokenPossiblyInvalid = /\A(.*)#{TagStart}\s*(\w+)\s*(.*)?#{TagEnd}\z/om

    def parse(tokens)
      ensure_valid_markup(tag_name, markup, options)
      @body = +''
      while (token = tokens.shift)
        if token =~ FullTokenPossiblyInvalid
          @body << Regexp.last_match(1) if Regexp.last_match(1) != ""
          return if block_delimiter == Regexp.last_match(2)
        end
        @body << token unless token.empty?
      end

      raise SyntaxError, options.locale.t("errors.syntax.tag_never_closed", block_name: block_name)
    end

    def render_to_output_buffer(_context, output)
      output << @body
      output
    end

    def nodelist
      [@body]
    end

    def blank?
      @body.empty?
    end

    protected

    def ensure_valid_markup(tag_name, markup, parse_context)
      unless Syntax.match?(markup)
        raise SyntaxError, parse_context.locale.t("errors.syntax.tag_unexpected_args", tag: tag_name)
      end
    end
  end

  Template.register_tag('raw', Raw)
end
