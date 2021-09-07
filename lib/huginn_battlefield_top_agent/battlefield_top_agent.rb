module Agents
  class BattlefieldTopAgent < Agent
    include FormConfigurable
    can_dry_run!
    default_schedule 'every_1d'

    description <<-MD
      This agent fetch stats from user's informations and creates a top score for R6 Games

      `debug` is used for verbose mode.
    MD

    def default_options
      {
        'users' => 'user1 user2 user3 user4',
        'debug' => 'false',
        'changes_only' => 'true'
      }
    end
    form_configurable :users, type: :string
    form_configurable :debug, type: :boolean
    form_configurable :changes_only, type: :boolean
    form_configurable :top_type, type: :array, values: ['longestHeadshot', 'headshots', 'deaths']
    form_configurable :bf_version, type: :array, values: ['bf3', 'bf4']

    def validate_options
      unless options['users'].present?
        errors.add(:base, "users is a required field")
      end

      if options.has_key?('changes_only') && boolify(options['changes_only']).nil?
        errors.add(:base, "if provided, changes_only must be true or false")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def check
      top_battlefield interpolated['users']
    end

    private

    def top_battlefield(users)
      top = []
      payload = { "type" => "#{interpolated['top_type']}","game" => "#{interpolated['bf_version']}" , "classement" => {} }
      log "top #{interpolated['top_type']}  launched"
      users_array = users.split(" ")
      users_array.each do |item, index|
          json = fetch_id(item)
          username  = json[:username]
          case interpolated['bf_version']
          when "bf3"
            nbr_suicide = json['data']['overviewStats'][interpolated['top_type']]
          when "bf4"
            nbr_suicide = json['data']['generalStats'][interpolated['top_type']]
          when bf2042
          end
          if interpolated['debug'] == 'true'
            log "#{username} #{nbr_suicide}"
          end
          top << { :username => username, :nbr => nbr_suicide }
      end
      top = top.sort_by { |hsh| hsh[:nbr] }.reverse
      top.each do |top|
        if interpolated['debug'] == 'true'
          log "#{top[:username]}: #{top[:nbr]}"
        end
        payload.deep_merge!({"classement" => { "#{top[:username]}" => "#{top[:nbr]}" }})
      end
      log "conversion done"
      if interpolated['changes_only'] == 'true'
        if payload.to_s != memory['top_suicide']
          memory['top_suicide'] = payload.to_s
          create_event payload: payload.to_json
        end
      else
        create_event payload: payload
        if payload.to_s != memory['top_suicide']
          memory['top_suicide'] = payload
        end
      end
    end

    def fetch_id(id)
      url = 'https://battlelog.battlefield.com/' + "#{interpolated['bf_version']}" + '/user/overviewBoxStats/' + id + '/'
      uri = URI.parse(url)
      request = Net::HTTP::Get.new(uri)
      request["Connection"] = "keep-alive"
      request["Accept"] = "*/*"
      request["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36"
      request["X-Requested-With"] = "XMLHttpRequest"
      request["Sec-Gpc"] = "1"
      request["Sec-Fetch-Site"] = "same-origin"
      request["Sec-Fetch-Mode"] = "cors"
      request["Sec-Fetch-Dest"] = "empty"
      request["Accept-Language"] = "fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7"
      
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      if interpolated['debug'] == 'true'
        log "request status for #{id} : #{response.code}"
        log "payload for #{id} : #{response.body}"
      end
      obj1 = JSON.parse(response.body)
      if interpolated['debug'] == 'true'
        log "personaId for #{id} : #{obj1['data']['soldiersBox'][0]['persona']['personaId']}"
      end
      fetch(obj1['data']['soldiersBox'][0]['persona']['personaId'],obj1['data']['soldiersBox'][0]['persona']['personaName'])
    end

    def fetch(user,username)
      case interpolated['bf_version']
      when "bf3"
        url = 'https://battlelog.battlefield.com/' + interpolated['bf_version'] + '/overviewPopulateStats/' + user + '/None/1/'
      when "bf4"
        url = 'https://battlelog.battlefield.com/' + interpolated['bf_version'] + '/warsawdetailedstatspopulate/' + user + '/1/'
      when bf2042
      end
      uri = URI.parse(url)
      request = Net::HTTP::Get.new(uri)
      request["Connection"] = "keep-alive"
      request["Accept"] = "*/*"
      request["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36"
      request["X-Requested-With"] = "XMLHttpRequest"
      request["Sec-Gpc"] = "1"
      request["Sec-Fetch-Site"] = "same-origin"
      request["Sec-Fetch-Mode"] = "cors"
      request["Sec-Fetch-Dest"] = "empty"
      request["Accept-Language"] = "fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7"
      
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      if interpolated['debug'] == 'true'
        log "request status for #{user} : #{response.code}"
        log "payload for #{user} : #{response.body}"
      end
      obj = JSON.parse(response.body)
      obj[:username] = username
      if interpolated['debug'] == 'true'
        log "payload updated for #{user} : #{obj.merge({ :username => username })}"
      end
      return obj.merge({ :username => username })
    end
  end
end
