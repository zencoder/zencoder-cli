module Zencoder::CLI::Command

  class Jobs < Base
    provides "jobs", "jobs" => { :description => "Lists the most recent jobs",
                                 :options => proc{|t|
                                   t.opt :number, "Number of jobs returned per page. Default 10.", :type => Integer
                                   t.opt :page,   "Jobs page number. Default 1.", :type => Integer
                                   t.opt :long,   "Will not truncate filenames.", :default => false
                                   t.opt :state,  "Filter the job list by job state", :type => String
                                 }},
                     "jobs:create" => { :description => "Create a job by passing a JSON string or filename",
                                        :help => "Create a job by passing either a JSON string or the path to a file containing JSON.\n\nExamples:\nzencoder jobs:create '{ \"input\": \"http://example.com/movie.mp4\" }'\nzencoder jobs:create /path/to/file.json",
                                        :arguments => ["json_string_or_path_to_file"] }
    class << self

      def run(args, global_options, command_options)
        jobs = Zencoder::Job.list(:base_url => Zencoder.base_url(global_options[:environment]),
                                  :per_page => command_options[:number] || 10,
                                  :page => command_options[:page] || 1,
                                  :state => command_options[:state].try(:downcase)).process_for_cli.body
        if jobs.any?
          jobs_table = table do |t|
            t.headings = ["ID", "Created", "Filename", "Duration", "Size", "Test", "State"]
            jobs.each do |job|
              duration = job["job"]["input_media_file"]["duration_in_ms"] ? (job["job"]["input_media_file"]["duration_in_ms"]/1000).to_s+"s" : "---"
              filesize = job["job"]["input_media_file"]["file_size_bytes"] ? ("%0.2f" % (job["job"]["input_media_file"]["file_size_bytes"].to_f/1.megabyte))+" MB" : "---"
              t << [
                job["job"]["id"],
                format_date(job["job"]["created_at"]),
                truncate(File.basename(job["job"]["input_media_file"]["url"]), :length => command_options[:long] ? 256 : 25),
                { :value => duration, :alignment => :right },
                { :value => filesize, :alignment => :right },
                job["job"]["test"] ? "YES" : "NO",
                job["job"]["state"].titleize
              ]
            end
          end
          puts jobs_table
        else
          puts "No jobs found."
        end
      end

      def create(args, global_options, command_options)
        arg = args.shift
        if arg.blank?
          puts "You must pass either a JSON string or the path to a file containing JSON."
          exit 1
        end
        begin
          json = JSON.parse(arg.to_s.first == "{" ? arg : File.read(arg))
        rescue JSON::ParserError => e
          puts "Invalid JSON: #{e.message}"
          exit 1
        rescue Errno::ENOENT => e
          puts e.message
          exit 1
        end

        response = Zencoder::Job.create(json, :base_url => Zencoder.base_url(global_options[:environment])).process_for_cli.body

        rows = []
        rows << ["ID", response["id"]]
        rows << ["Test", response["test"]] if response["test"]
        puts table([{ :value => "Job", :colspan => 2 }], *rows)
        puts

        response["outputs"].each_with_index do |output, i|
          rows = []
          rows << ["ID", output["id"]]
          rows << ["Label", output["label"]] if output["label"]
          rows << ["URL", output["url"]]
          puts table([{ :value => "Output ##{i+1}", :colspan => 2 }], *rows)
          puts
        end
      end

    end
  end


  class Job < Base
    provides "job",  "job"          => { :description => "Show job details by ID",
                                         :arguments => ["job_id"] },
                     "job:open"     => { :description => "Opens the job in the dashboard",
                                         :arguments => ["job_id"] },
                     "job:resubmit" => { :description => "Resubmit a job by ID",
                                         :arguments => ["job_id"] },
                     "job:cancel"   => { :description => "Cancels a job by ID",
                                         :arguments => ["job_id"] },
                     "job:delete"   => { :description => "Deletes a job by ID",
                                         :arguments => ["job_id"] }
    class << self

      def run(args, global_options, command_options)
        job_id = extract_id(args)
        job = Zencoder::Job.details(job_id, :base_url => Zencoder.base_url(global_options[:environment])).process_for_cli.body["job"]
        rows = []
        rows << ["ID", job["id"]]
        rows << ["Created", format_date(job["created_at"])]
        rows << ["Finished", format_date(job["finished_at"])] if job["finished_at"]
        rows << ["Pass Through", job["pass_through"]] if job["pass_through"]
        rows << ["Test", job["test"] ? "YES" : "NO"]
        rows << ["State", job["state"].titleize]
        puts table([{ :value => "Job", :colspan => 2 }], *rows)
        puts

        input = job["input_media_file"]
        rows = []
        rows << ["ID", input["id"]]
        rows << ["URL", input["url"]]
        rows << ["State", input["state"].titleize]
        rows << ["Duration", (input["duration_in_ms"]/1000).to_s+" seconds"] if input["duration_in_ms"]
        rows << ["Size", ("%0.2f" % (input["file_size_bytes"].to_f/1.megabyte))+" MB"] if input["file_size_bytes"]
        rows << ["Format", input["format"]] if input["format"]
        if input["state"] == "finished"
          rows << :separator
          rows << ["Video Codec", input["video_codec"]] if input["video_codec"]
          rows << ["Resolution", input["width"].to_s+"x"+input["height"].to_s] if input["width"] && input["height"]
          rows << ["Video Bitrate", input["video_bitrate_in_kbps"].to_s+" Kbps"] if input["video_bitrate_in_kbps"]
          rows << ["Frame Rate", input["frame_rate"]] if input["frame_rate"]
          rows << :separator
          rows << ["Audio Codec", input["audio_codec"]] if input["audio_codec"]
          rows << ["Audio Bitrate", input["audio_bitrate_in_kbps"].to_s+" Kbps"] if input["audio_codec"]
          rows << ["Sample Rate", input["audio_sample_rate"]] if input["audio_sample_rate"]
          rows << ["Channels", input["channels"]] if input["channels"]
        end
        if input["error_class"] || input["error_message"]
          rows << :separator
          rows << ["Error Class", input["error_class"]] if input["error_class"]
          rows << ["Error Message", input["error_message"]] if input["error_message"]
        end
        puts table([{ :value => "Input", :colspan => 2 }], *rows)
        puts

        job["output_media_files"].each_with_index do |output, i|
          rows = []
          rows << ["ID", output["id"]]
          rows << ["Label", output["label"]] if output["label"]
          rows << ["URL", output["url"]]
          rows << ["State", output["state"].titleize]
          rows << ["Duration", (output["duration_in_ms"]/1000).to_s+" seconds"] if output["duration_in_ms"]
          rows << ["Size", ("%0.2f" % (output["file_size_bytes"].to_f/1.megabyte))+" MB"] if output["file_size_bytes"]
          rows << ["Format", output["format"]] if output["format"]
          if output["state"] == "finished"
            rows << :separator
            rows << ["Video Codec", output["video_codec"]] if output["video_codec"]
            rows << ["Resolution", output["width"].to_s+"x"+output["height"].to_s] if output["width"] && output["height"]
            rows << ["Video Bitrate", output["video_bitrate_in_kbps"].to_s+" Kbps"] if output["video_bitrate_in_kbps"]
            rows << ["Frame Rate", output["frame_rate"]] if output["frame_rate"]
            rows << :separator
            rows << ["Audio Codec", output["audio_codec"]] if output["audio_codec"]
            rows << ["Audio Bitrate", output["audio_bitrate_in_kbps"].to_s+" Kbps"] if output["audio_codec"]
            rows << ["Sample Rate", output["audio_sample_rate"]] if output["audio_sample_rate"]
            rows << ["Channels", output["channels"]] if output["channels"]
          end
          if output["error_class"] || output["error_message"]
            rows << :separator
            rows << ["Error Class", output["error_class"]] if output["error_class"]
            rows << ["Error Message", output["error_message"]] if output["error_message"]
          end
          puts table([{ :value => "Output ##{i+1}", :colspan => 2 }], *rows)
          puts
        end
      end

      def open(args, global_options, command_options)
        job_id = extract_id(args)
        `open https://app.zencoder.com/jobs/#{job_id}`
      end

      def resubmit(args, global_options, command_options)
        job_id = extract_id(args)
        response = Zencoder::Job.resubmit(job_id, :base_url => Zencoder.base_url(global_options[:environment])).process_for_cli
        puts "Job ##{job_id} resubmitted."
      end

      def cancel(args, global_options, command_options)
        job_id = extract_id(args)
        response = Zencoder::Job.cancel(job_id, :base_url => Zencoder.base_url(global_options[:environment])).process_for_cli
        puts "Job ##{job_id} cancelled."
      end

      def delete(args, global_options, command_options)
        job_id = extract_id(args)
        response = Zencoder::Job.delete(job_id, :base_url => Zencoder.base_url(global_options[:environment])).process_for_cli
        puts "Job ##{job_id} deleted."
      end

    end

  end
end
