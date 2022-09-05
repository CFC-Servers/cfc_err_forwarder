import Config from CFCErrForwarder

GIST_URL = "https://api.github.com/gists?scope=gist"
return (content) ->
    timestamp = os.time!
    niceDate = os.date "%H:%M:%S - %d/%m/%Y" , timestamp

    success, status, body, headers = reqwest
        url: GIST_URL
        blocking: true
        headers: "Authorization": "token #{token}"
        payload: util.TableToJSON
            public: false
            files: "error_#{timestamp}": :content
            description: "Error occurred: #{niceDate}"

    if success
        link = util.JSONToTable(body)
        return link["html_url"]

    ErrorNoHaltWithStack "Failed to create Gist!"
    Logger\warn "Status: ", status
    Logger\warn "Body: ", body
