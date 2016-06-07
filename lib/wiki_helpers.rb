# Various useful functions for Middleman-based sites
class WikiHelpers < Middleman::Extension
  def initialize(app, options_hash = {}, &block)
    super
  end

  helpers do
    def load_redirects
      return $helper_wiki_redirects if $helper_wiki_redirects

      slashes = /^\/|\/$/

      redirects = File.readlines "#{root}/#{source}/redirects.yaml"

      $helper_wiki_redirects ||= redirects.map do |line|
        splits = line.split(': ')

        {
          from: splits.first.gsub(slashes, '').strip,
          to: splits.last.gsub(slashes, '').strip
        }
      end.compact
    end

    def find_wiki_page(searchkey)
      searchkey.sub!(/^ /, '#') # Weird wiki-ism

      extra = /[#\?].*/
      url_extra = searchkey
                  .match(extra).to_s
                  #.tr('_', '-').tr(' ', '-')
                  #.downcase.squeeze('-')

      url_fixed = searchkey
                  .sub(extra, '').tr('_', ' ')
                  .gsub(/^\/|\/$/, '')
                  .downcase

      match_redir = load_redirects.map do |redir|
        next if url_fixed.empty?

        exact_match = redir[:from].downcase == url_fixed
        page_match = redir[:from].downcase.end_with?("/#{url_fixed}")

        redir[:to].downcase.tr('_', ' ') if exact_match || page_match
      end.compact

      result = sitemap.resources.select do |resource|
        next unless resource.data.wiki_title

        wiki_title = resource.data.wiki_title.to_s.downcase.strip

        # Check direct matches
        matches ||= wiki_title == url_fixed

        # Handle redirects
        matches ||= match_redir.include? wiki_title

        matches
      end

      # Return the URL with the extra hash
      result.map { |resource| resource.url + url_extra }.last
    end
  end
end

::Middleman::Extensions.register(:wiki_helpers, WikiHelpers)
