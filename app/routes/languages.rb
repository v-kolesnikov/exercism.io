require_relative '../../x'

module ExercismWeb
  module Routes
    class Languages < Core
      TOPICS = %w(about exercises installing tests learning resources help launch contribute todo).freeze

      get '/languages' do
        tracks = X::Track.all
        active, inactive = tracks.partition(&:active?)
        planned, inactive = inactive.partition(&:planned?)
        inactive.sort! { |a, b| b.problems.count <=> a.problems.count }
        erb :"languages/index", locals: { active: active, inactive: inactive, planned: planned }
      end

      get '/repositories' do
        active, inactive = X::Track.all.partition(&:active?)
        inactive.sort! { |a, b| b.problems.count <=> a.problems.count }
        planned, upcoming = inactive.partition(&:planned?)
        erb :"languages/repositories", locals: { active: active, inactive: inactive,
                                                 planned: planned, upcoming: upcoming }
      end

      get '/languages/:track_id' do |track_id|
        _, body = X::Xapi.get('tracks', track_id)
        parsed_body = JSON.parse(body)
        if parsed_body['error'] == "No track '#{track_id}'"
          status 404
          erb :"languages/not_found", locals: { track_id: track_id }
        else
          track = X::Track.new(parsed_body['track'])
          topic = track.active? ? "about" : "launch"
          redirect "/languages/%s/%s" % [track_id, topic]
        end
      end

      get '/languages/:track_id/:topic' do |track_id, topic|
        template = topic
        unless TOPICS.include?(topic)
          status 404
          template = "topic_not_found"
        end

        _, body = X::Xapi.get('tracks', track_id)
        parsed_body = JSON.parse(body)
        if parsed_body['error'] == "No track '#{track_id}'"
          language_not_found(track_id)
        else
          track = X::Track.new(parsed_body['track'])
          erb :"languages/language", locals: {
            track: track,
            topic: topic,
            template: template,
            docs: X::Docs::Launch.new(track.repository, track.checklist_issue),
          }
        end
      end

      def language_not_found(track_id)
        status 404
        erb :"languages/not_found", locals: { track_id: track_id }
      end
    end
  end
end
