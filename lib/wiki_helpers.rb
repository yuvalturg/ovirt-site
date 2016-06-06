# Various useful functions for Middleman-based sites
class WikiHelpers < Middleman::Extension
  def initialize(app, options_hash = {}, &block)
    super
  end

  helpers do
    def load_redirects
      return $helper_wiki_redirects if $helper_wiki_redirects

      redirects = File.readlines "#{root}/#{source}/redirects.yaml"

      match_redir = redirects.map do |line|
        splits = line.split(':')

        { from: splits.first.strip, to: splits.last.strip }
      end.compact

      $helper_wiki_redirects ||= match_redir
    end

    def find_wiki_page(searchkey)
      extra = /[#\?].*/
      url_extra = searchkey.match(extra).to_s
      url_fixed = searchkey.tr('_', ' ').gsub(extra, '')

      searchkey.gsub!(extra, '')

      match_redir = load_redirects.select do |redir|
        #redir[:to].downcase if redir[:from].match(/(^|\/)#{searchkey}$/i)
        redir[:to].downcase if redir[:from].end_with? "/#{searchkey.downcase}"
      end

      sitemap.resources.select do |resource|
        next unless resource.data.wiki_title

        # Check direct matches
        matches ||= resource.data.wiki_title.to_s.downcase.strip == url_fixed.tr('_', ' ').downcase.strip
        #matches ||= resource.data.wiki_title.strip[/(^|\/)#{searchkey}$/i]
        #matches ||= resource.data.wiki_title.downcase.strip.end_with? "/#{searchkey.downcase}"
        # Handle redirects
        matches ||= match_redir.include? resource.data.wiki_title.downcase

        matches
      end.map do |resource|
        resource.url + url_extra
      end.first
    end
  end
end

::Middleman::Extensions.register(:wiki_helpers, WikiHelpers)
