# typed: true
# frozen_string_literal: true

class Views::Pages::Landing < Views::Base
  # == View ==

  sig { override.void }
  def view_template
    Components::Layout(site_title:, body_class: "no-dark bg-[#fdfdfd]") do
      main(class: [
        "max-w-4xl mx-auto px-6 py-12 space-y-24",
        "antialiased text-gray-800",
        "selection:bg-landing-primary/20 selection:text-landing-primary",
      ]) do
        render_hero
        render_cta
        render_featured_in
        render_how_it_works

        div(class: "grid md:grid-cols-2 gap-8 md:gap-12") do
          render_for_guests
          render_for_hosts
        end

        render_gatherings
        render_closing
        render_footer
      end
    end
  end

  private

  # == Helpers ==

  sig { returns(T.nilable(String)) }
  def site_title
    config = Rails.configuration.x
    [config.site_name, config.site_tagline].compact.join(" | ").presence
  end

  sig { void }
  def render_hero
    section(class: "text-center space-y-8 sm:pt-12 mb-8") do
      div(class: "flex flex-col items-center gap-y-4") do
        div(class: "flex justify-center") do
          image_tag(
            "logo-text.png",
            alt: "happy town logo",
            class: "w-50",
          )
        end
        div(class: "flex gap-4 font-bold text-landing-secondary") do
          a(
            href: "https://instagram.com/happytown.to",
            target: "_blank",
            class: "hover:underline w-20 text-end",
          ) { "instagram" }
          span(class: "text-gray-300") { "•" }
          a(
            href: "https://tiktok.com/@adamdriversbod",
            target: "_blank",
            class: "hover:underline w-20 text-start",
          ) { "tiktok" }
        end
      end
    end
  end

  sig { void }
  def render_cta
    section(class: "max-w-3xl mx-auto text-center space-y-8 mb-8") do
      h2(
        class: "text-4xl sm:text-5xl font-bold sm:max-xl max-w-2xl mx-auto leading-[1.1]",
      ) { "a new kind of third space in toronto." }
      div(class: "flex flex-col sm:flex-row gap-4 justify-center items-center") do
        a(href: "#gatherings", class: "landing_btn_primary") { "see upcoming gatherings" }
        a(href: "#host", class: "landing_btn_secondary") { "host with us →" }
      end
      image_tag(
        "banner.png",
        alt: "happy town banner",
        class: "h-60 mx-auto rounded-3xl object-cover shadow-sm mt-4",
      )
    end
  end

  sig { void }
  def render_featured_in
    section(class: "space-y-2") do
      h2(class: "text-2xl font-bold text-center text-gray-500") { "featured in" }
      div(
        class: "flex flex-wrap max-w-92 sm:max-w-none sm:flex-nowrap justify-center mx-auto items-center gap-x-5 gap-y-4 sm:gap-8",
      ) do
        a(
          href: "https://globalnews.ca/news/11610040/toronto-community-meetups-in-path/",
          target: "_blank",
          class: "w-26",
        ) do
          image_tag("landing/globalnews.svg", alt: "Global News")
        end
        a(
          href: "https://www.cbc.ca/listen/live-radio/1-82-here-and-now-toronto/clip/16192815-a-meet-group-takes-torontos-underground-path",
          target: "_blank",
          class: "w-30",
        ) do
          image_tag("landing/cbc.svg", alt: "CBC")
        end
        a(
          href: "https://toronto.citynews.ca/video/",
          target: "_blank",
          class: "w-32",
        ) do
          image_tag("landing/citynews.svg", alt: "CityNews")
        end
        a(
          href: "https://www.torontotoday.ca/local/arts-culture/aura-underground-food-court-third-space-11732365",
          target: "_blank",
          class: "w-26",
        ) do
          image_tag("landing/torontotoday.jpeg", alt: "Toronto Today")
        end
        a(
          href: "https://nowtoronto.com/lifestyle/toronto-residents-are-hosting-walking-clubs-in-the-path/",
          target: "_blank",
          class: "w-20",
        ) do
          image_tag("landing/now-toronto.jpeg", alt: "Now Toronto")
        end
        a(
          href: "https://us.cnn.com/2026/02/17/travel/toronto-path-canada-underground-networks",
          target: "_blank",
          class: "w-24",
        ) do
          image_tag("landing/cnn.svg", alt: "CNN")
        end
      end
    end
  end

  sig { void }
  def render_how_it_works
    section(class: "space-y-6") do
      h2(class: "text-3xl font-bold text-center") { "how this works" }
      div(class: "bg-landing-secondary/5 p-8 md:p-12 rounded-3xl space-y-5") do
        div(class: "space-y-2") do
          p(class: "text-xl font-medium") do
            "find a gathering, show up, and make toronto feel a little more like home."
          end
          p(class: "text-xl font-medium") do
            "we host recurring events in low-traffic spaces where you can enjoy spending time with others."
          end
        end
        ul(class: "grid md:grid-cols-2 gap-x-6 gap-y-3") do
          li(class: "flex gap-3") do
            span(class: "text-landing-secondary text-xl") { "✦" }
            span do
              strong { "low cost to free:" }
              plain(" making it so hanging out doesn't stretch your budget.")
            end
          end
          li(class: "flex gap-3") do
            span(class: "text-landing-secondary text-xl") { "✦" }
            span do
              strong { "light structure for hosts:" }
              plain(%( guidance that helps you feel like "you've got this".))
            end
          end
          li(class: "flex gap-3") do
            span(class: "text-landing-secondary text-xl") { "✦" }
            span do
              strong { "a place to be yourself:" }
              plain(" no networking, please! just bring the \"5-9\" you :)")
            end
          end
          li(class: "flex gap-3") do
            span(class: "text-landing-secondary text-xl") { "✦" }
            span do
              strong { "a respectful relationship with spaces:" }
              plain(" we gather responsibly and encourage support for local shops nearby.")
            end
          end
        end
      end
    end
  end

  sig { void }
  def render_for_guests
    section(class: "landing_outline_card border-landing-primary/10") do
      h2 do
        plain("for guests ")
        span(
          class: "text-gray-400 font-normal text-lg align-baseline",
        ) { "(what you can expect)" }
      end

      div(class: "space-y-2") do
        p(class: "font-bold") { "you'll probably like happy town if you..." }
        ul(class: "space-y-2 text-gray-600 *:pl-4 *:border-l-2 *:border-landing-primary/20") do
          li { "want new friends but hate \"networking energy\"" }
          li { "like long walks and wandering conversations" }
          li { "miss the feeling of a friendly regular spot" }
          li { "enjoy gentle structure: prompts, activities, \"you can join anytime\" vibes" }
        end
      end

      div(class: "space-y-2") do
        p(class: "font-bold") { "what you won't have to do" }
        ul(class: "space-y-2 text-gray-600 *:pl-4 *:border-l-2 *:border-landing-primary/20") do
          li { "pitch yourself" }
          li { "be extroverted on command" }
          li { "commit to a whole new identity" }
        end
      end

      a(
        href: "#gatherings",
        class: "landing_cta_btn bg-landing-primary hover:bg-landing-primary/90 mt-2",
      ) do
        span { "pick a gathering this week" }
        Icon("huge/arrow-right-02", class: "size-5")
      end
    end
  end

  sig { void }
  def render_for_hosts
    section(
      id: "host",
      class: "landing_outline_card border-landing-secondary/10",
    ) do
      h2 { "host with us." }
      div(class: "space-y-1") do
        p(class: "text-lg font-bold") { "let's create a third space together :)" }
        p(class: "text-gray-600") { "for those who like to create spaces where others feel at home." }
      end

      div(class: "space-y-2") do
        p(class: "font-bold") { "we're especially into hosts who love:" }
        ul(class: "space-y-2 text-gray-600 *:pl-4 *:border-l-2 *:border-landing-secondary/20") do
          li { "calm facilitation" }
          li { "playful prompts" }
          li { "hobby tables (crafts, writing, sketching, reading hours, language corners, etc.)" }
          li { "small rituals that make strangers feel safe together" }
        end
      end

      a(
        href: "https://tally.so/r/81a9vr",
        class: "landing_cta_btn bg-landing-secondary hover:bg-landing-secondary/90 mt-2",
      ) do
        span { "host with happy town" }
        Icon("huge/arrow-right-02", class: "size-5")
      end
    end
  end

  sig { void }
  def render_gatherings
    section(id: "gatherings", class: "space-y-6 lg:space-y-8") do
      h2(class: "text-3xl font-bold text-center") { "featured gatherings" }

      div(class: "grid md:grid-cols-2 gap-6 lg:gap-8") do
        div(class: "landing_gathering_card") do
          div(class: "w-full flex flex-col items-center gap-y-4 mb-4") do
            image_tag(
              "landing/mindful-miles-profile.jpg",
              alt: "mindful miles profile",
              class: "size-40 rounded-2xl object-cover",
            )
            div(
              class: "bg-landing-primary/10 text-landing-primary px-3 py-1 rounded-full text-sm font-bold",
            ) do
              "walk with us"
            end
          end
          h3(class: "text-2xl font-bold mb-2") { "mindful miles" }
          p(class: "text-gray-500 mb-4 font-medium") do
            "a winter PATH walk for wandering conversations. 10k-ish steps at 8am every saturday."
          end
          render_gathering_button(
            "mindful miles",
            slug: "mindfulmiles",
            class: "text-landing-primary",
          )
        end

        div(class: "landing_gathering_card") do
          div(class: "w-full flex flex-col items-center gap-y-4 mb-4") do
            image_tag(
              "landing/foodcourt-fairgrounds-profile.png",
              alt: "foodcourt fairgrounds profile",
              class: "size-40 rounded-2xl object-cover",
            )
            div(
              class: "bg-landing-secondary/10 text-landing-secondary px-3 py-1 rounded-full text-sm font-bold",
            ) do
              "create with us"
            end
          end
          h3(class: "text-2xl font-bold mb-2") { "foodcourt fairgrounds" }
          p(class: "text-gray-500 mb-4 font-medium") do
            "a cozy post-walk third-space hang: low-key activities in the aura concourse basement food court."
          end
          render_gathering_button(
            "foodcourt fairgrounds",
            slug: "foodcourt-fairgrounds",
            class: "text-landing-secondary",
          )
        end
      end

      p(class: "text-center text-gray-500 italic") do
        "...and more gatherings coming soon!"
      end
    end
  end

  sig { params(name: String, slug: String, attributes: T.untyped).void }
  def render_gathering_button(name, slug:, **attributes)
    a(
      href: "https://luma.com/#{slug}?utm_source=happytown.life",
      target: "_blank",
      **mix(
        { class: "landing_gathering_btn" },
        **attributes,
      ),
    ) do
      span { "view #{name}" }
      Icon("huge/arrow-right-02", class: "size-5")
    end
  end

  sig { void }
  def render_closing
    section(class: "text-center space-y-8 py-16 bg-linear-to-b from-transparent to-landing-primary/5 rounded-3xl") do
      div(class: "flex justify-center") do
        image_tag(
          "logo-text.png",
          alt: "happy town logo",
          class: "w-32 md:w-48",
        )
      end
      h2(class: "text-4xl md:text-5xl font-bold") { "come claim a third space." }
      p(class: "text-xl text-gray-600") do
        "find a gathering, show up, and make toronto feel a little more like home."
      end

      div(class: "flex flex-col sm:flex-row gap-4 justify-center items-center") do
        a(href: "#gatherings", class: "landing_btn_primary") { "see upcoming gatherings" }
        a(href: "#host", class: "landing_btn_secondary") do
          span { "host with us" }
          Icon("huge/arrow-right-02", class: "size-5")
        end
      end
    end
  end

  sig { void }
  def render_footer
    footer(class: "text-center text-gray-400 text-sm pb-8 space-y-4") do
      div(class: "flex justify-center gap-4 font-bold text-landing-secondary") do
        a(
          href: "https://instagram.com/happytown.to",
          target: "_blank",
          class: "hover:underline w-20 text-end",
        ) { "instagram" }
        span(class: "text-gray-300") { "•" }
        a(
          href: "https://tiktok.com/@adamdriversbod",
          target: "_blank",
          class: "hover:underline w-20 text-start",
        ) { "tiktok" }
      end
      p { "© 2026 happy town. all rights reserved (but share the vibe freely)." }
    end
  end
end
