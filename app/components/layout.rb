# typed: true
# frozen_string_literal: true

class Components::Layout < Components::Base
  include Phlex::Rails::Helpers::CSRFMetaTags
  include Phlex::Rails::Helpers::CSPMetaTag
  include Phlex::Rails::Helpers::StyleSheetLinkTag
  include Phlex::Rails::Helpers::JavaScriptIncludeTag
  include Phlex::Rails::Helpers::Flash

  sig { params(title: T.nilable(String), site_name: String, options: T.untyped).void }
  def initialize(title: nil, site_name: ItsKai.site_name, **options)
    super(**options)
    @title = title
    @site_name = site_name
  end

  sig { override.params(block: T.nilable(T.proc.void)).void }
  def view_template(&block)
    doctype

    html do
      head do
        title { computed_title }

        meta(name: "viewport", content: "width=device-width,initial-scale=1")
        meta(name: "apple-mobile-web-app-capable", content: "yes")
        meta(name: "application-name", content: @site_name)
        meta(name: "mobile-web-app-capable", content: "yes")

        csrf_meta_tags
        csp_meta_tag

        # == Favicons
        link(rel: "shortcut icon", href: "/favicon.ico")
        link(rel: "icon", href: "/favicon-96x96.png", type: "image/png", sizes: "96x96")
        link(rel: "icon", href: "/favicon.svg", type: "image/svg+xml")
        link(rel: "apple-touch-icon", sizes: "180x180", href: "/apple-touch-icon.png")
        link(rel: "manifest", href: "/site.webmanifest")

        # == Fonts
        link(rel: "preconnect", href: "https://fonts.googleapis.com")
        link(rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: true)
        link(rel: "stylesheet", href: "https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght@0,14..32,100..900;1,14..32,100..900&display=swap")

        # == Assets
        stylesheet_link_tag("application", "data-turbo-track": "reload")
        javascript_include_tag("application", "data-turbo-track": "reload", type: "module")
      end

      body(class: "flex min-h-dvh flex-col") do
        render_header
        render_flash(class: "m-4 self-center")
        yield if block_given?
      end
    end
  end

  # == Methods ==

  sig { params(options: T.untyped, block: T.proc.void).void }
  def page_container(**options, &block)
    other_class = options.delete(:class)
    div(
      class: class_names("page_container", other_class),
      **options,
      &block
    )
  end

  private

  # == Helpers ==

  sig { returns(String) }
  def computed_title
    [@title, @site_name].compact.join(" | ")
  end

  sig { params(options: T.untyped).void }
  def render_flash(**options)
    message = flash[:notice] || flash[:alert] or return
    class_option = options.delete(:class)
    render Components::Card.new(
      size: :sm,
      class: class_names(
        "flash card",
        { "flash-alert": flash.key?(:alert) },
        class_option,
      ),
      **options,
    ) do |card|
      card.content(class: "font-medium") do
        message
      end
    end
  end

  sig { void }
  def render_header
    header(class: "flex justify-center p-2 border-b border-border") do
      render Components::Button.new(
        component: "a",
        variant: :ghost,
        href: root_path,
      ) do
        image_tag(
          "icon.png",
          alt: "#{@site_name} logo",
          class: "size-5 dark:size-5.5 dark:p-[2px] dark:rounded-full dark:bg-accent-foreground",
          data: { icon: "inline-start" },
        )
        span(class: "font-bold text-lg") do
          @site_name
        end
      end
    end
  end
end
