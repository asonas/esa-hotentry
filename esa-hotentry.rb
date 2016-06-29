require 'esa'
require 'erb'

module EsaHotentry
  def self.generate_ranking
    fetcher = Fetcher.new

    rank = fetcher.posts.sort_by do |post|
      post.point
    end.reverse

    puts Template.render(rank)
  end

  class Post
    attr_accessor :point, :title, :url, :stargazers_count, :watchers_count, :comments_count

    STARGAZER_POINT = 10
    COMMENT_POINT = 5
    WATCH_POINT = 1

    def initialize(raw_post)
      @title = raw_post["title"]
      @stargazers_count = raw_post["stargazers_count"]
      @comments_count = raw_post["comments_count"]
      @watchers_count = raw_post["watchers_count"]
      @body_md = raw_post["body_md"]
      @url = raw_post["url"]
      @number = raw_post["number"]
      @title = raw_post["full_name"]
      @point = sum_point
    end

    def summary
      @body_md.gsub("\r\n", "")[1..100]
    end

    # decorator
    def link
      "[#{@title}](#{@url})"
    end

    private
    def sum_point
      stargazers_point  + comments_point + watchers_point
    end

    def stargazers_point
      @stargazers_count * STARGAZER_POINT
    end

    def comments_point
      @comments_count * COMMENT_POINT
    end

    def watchers_point
      @watchers_count * WATCH_POINT
    end
  end

  class Fetcher
    attr_accessor :posts
    def initialize
      @client = Esa::Client.new(access_token: ENV["ESA_ACCESS_TOKEN"], current_team: ENV["ESA_TEAM"])

      fetch_all_posts
    end

    def fetch_all_posts
      date = Date.new(2016, 6, 22).strftime("%Y-%m-%d")
      res = @client.posts(q: "created:>#{date}", per_page: 100)
      @posts = res.body["posts"].map { |p| Post.new(p) }

      while res.body["next_page"] != nil
        res = @client.posts(q: "created:>#{date}", per_page: 100, page: res.body["next_page"])
        @posts += res.body["posts"].map { |p| Post.new(p) }
      end
    end
  end

  class Template
    def self.render(ranking)
      erb = ERB.new(File.read("template.md.erb"))
      puts erb.result(binding)
    end
  end

end

EsaHotentry.generate_ranking
