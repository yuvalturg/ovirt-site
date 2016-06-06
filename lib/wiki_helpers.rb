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

        #return nil if splits.first == '---' || splits.first.empty?

        { from: splits.first.strip, to: splits.last.strip }
      end.compact

      $helper_wiki_redirects ||= match_redir
    end

    def find_wiki_page(searchkey)
      puts "KEY #{searchkey}"
      extra = /[#\?].*/
      url_extra = searchkey.match(extra).to_s
      url_fixed = searchkey.tr('_', ' ').gsub(url_extra, '')

      searchkey.gsub!(extra, '')

      match_redir = load_redirects.select do |redir|
        #redir[:to].downcase if redir[:from].match(/(^|\/)#{url_fixed}$/i)
        redir[:to] if redir[:from].downcase.end_with? "/#{url_fixed.downcase}"
      end

      result = sitemap.resources.select do |resource|
        next unless resource.data.wiki_title

        # Check direct matches
        matches ||= resource.data.wiki_title.to_s.downcase.strip == url_fixed.tr('_', ' ').downcase.strip
        #matches ||= resource.data.wiki_title.strip[/(^|\/)#{url_fixed}$/i]
        matches ||= resource.data.wiki_title.downcase.strip.end_with? "/#{url_fixed.downcase}"
        # Handle redirects
        #matches ||= match_redir.include? resource.data.wiki_title.downcase
        #matches ||= match_redir.select { |m| m[:from].downcase.end_with? url_fixed.downcase }.count > 0

        # puts "REDIRS" + match_redir.select { |m| m[:from].end_with? url_fixed }.to_s if matches

        # puts "MATCHES #{matches}" if matches

        matches
      end.map do |resource|
        resource.url + url_extra
      end.first

      puts "END #{result}"

      result
    end
  end
end

::Middleman::Extensions.register(:wiki_helpers, WikiHelpers)
