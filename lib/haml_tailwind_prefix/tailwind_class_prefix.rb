module HamlLint
  class Linter::TailwindClassPrefix < Linter
    include LinterRegistry

    # NOTE: 全てのクラスを網羅できているわけではない
    BOOTSTRAP_EXCLUSIONS = [
      /^container$/,
      /^row$/,
      /^col(?:-[a-z]+(?:-\d+)?)*$/,
      /^btn(?:-[a-z]+)*$/,
      /^text-(?:center|left|right)$/,
      /^text-muted$/,
      /^text-sm$/,
      /^g-\d+$/,
      /^card$/,
      /^card-body$/,
      /^card-title$/,
      /^card-text$/,
      /^form-control$/,
      /^form-control-plaintext$/,
      /^form-check$/,
      /^form-check-input$/,
      /^form-check-label$/,
      /^form-range$/,
      /^form-select$/,
      /^form-text$/,
      /^form-label$/,
      /^form-floating$/,
      /^is-valid$/,
      /^is-invalid$/,
      /^was-validated$/,
      /^col-form-label$/,
      /^col-form-label-(?:sm|lg)$/
    ]

    # NOTE: 全てのクラスを網羅できているわけではない
    # 英数字、ハイフン、スラッシュ、ブラケットのみを許容
    TAILWIND_CLASS_REGEX = /^[A-Za-z0-9\-\[\]\/]+$/

    def visit_tag(node)
      classes = []

      if node.respond_to?(:static_classes) && node.static_classes
        classes.concat(node.static_classes)
      end

      if node.has_hash_attribute?('class')
        class_attr = node.hash_attributes['class']
        if class_attr.is_a?(String)
          classes.concat(class_attr.split)
        elsif class_attr.is_a?(Array)
          class_attr.each do |attr_value|
            if attr_value.is_a?(String)
              classes.concat(attr_value.split)
            else
              classes << attr_value.to_s
            end
          end
        end
      end

      classes = classes.flatten.map(&:to_s)
      puts "detected classes: #{classes.inspect}"

      classes.each do |full_class|
        base_class = full_class.split(':').last

        next if base_class.start_with?('tw-')

        next if BOOTSTRAP_EXCLUSIONS.any? { |regex| base_class =~ regex }

        if base_class =~ TAILWIND_CLASS_REGEX
          modifiers = full_class.include?(':') ? full_class.split(':')[0...-1].join(':') + ':' : ''
          suggested = "#{modifiers}tw-#{base_class}"
          record_lint(node, "TailwindCSSユーティリティクラス '#{full_class}' は'tw-'プレフィックスを付与してください（例: '#{suggested}'）")
        end
      end

      yield if block_given?
    end
  end
end
