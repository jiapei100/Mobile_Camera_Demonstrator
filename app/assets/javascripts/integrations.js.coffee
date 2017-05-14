user_email = undefined
lastSyncDateIs = undefined
api_key = undefined
api_id = undefined
syncIs = undefined
mac_address = undefined
iam_authenticated = undefined

window.startAuth = ->
  config = 
    apiKey: AuthData.apiKey
    authDomain: AuthData.authDomain
    databaseURL: AuthData.databaseURL
    storageBucket: AuthData.storageBucket

  window.firebase.initializeApp config
  window.storage = firebase.storage()
  window.storageRef = storage.ref()

sendAJAXRequest = (settings) ->
  token = $('meta[name="csrf-token"]')
  if token.size() > 0
    headers =
      "X-CSRF-Token": token.attr("content")
    settings.headers = headers
  xhrRequestChangeMonth = jQuery.ajax(settings)
  true

onLoad = ->
  $(window).load ->
    firebase.auth().onAuthStateChanged (user) ->
      if user
        console.log user.email
        user_email = user.email
        iam_authenticated = firebase
        db_auth = firebase.database().ref()
        obliged_email = "#{user_email}".replace(/\./g,'|')
        console.log obliged_email
        db_auth.once 'value', (snapshot) ->
          if !snapshot.hasChild(obliged_email)
            $("#integrate-me").css('display', 'block')
            $(".makeit-take").css('display', 'block')
            console.log "No data for SYNC"
          else
            db_auth.child("/#{obliged_email}").once 'value', (snapshot) ->
              if typeof Object.values(snapshot.val())[1] != 'undefined'
                syncIs = Object.values(snapshot.val())[1].syncIsOn
                if syncIs > 0
                  lastSyncDateIs = Object.values(snapshot.val())[1].lastSyncDate
                  mac_address = Object.keys(snapshot.val())[0]
                  api_key = Object.values(snapshot.val())[1].apiKey
                  api_id = Object.values(snapshot.val())[1].apiId
                  syncIs = Object.values(snapshot.val())[1].syncIsOn
                  $("#revoke-me").css('display', 'block')
                  $(".makeit-take").css('display', 'block')
                else
                  $("#integrate-me").css('display', 'block')
                  $(".makeit-take").css('display', 'block')
              else
                $("#integrate-me").css('display', 'block')
                $(".makeit-take").css('display', 'block')
        $('.profile-image').attr 'src', user.photoURL
        $('.profile-name').text user.displayName
      else
        window.location = '/'
      return
    return

window.startSync = (auth, email) ->
  db_auth = auth.database().ref()
  obliged_email = "#{email}".replace(/\./g,'|')
  console.log obliged_email
  db_auth.once 'value', (snapshot) ->
    if !snapshot.hasChild(obliged_email)
      $(".heyyou").css('display', 'block')
      console.log "No data for SYNC"
    else
      db_auth.child("/#{obliged_email}").once 'value', (snapshot) ->
        # if typeof Object.values(snapshot.val())[1] != 'undefined'
        lastSyncDateIs = Object.values(snapshot.val())[1].lastSyncDate
        mac_address = Object.keys(snapshot.val())[0]
        api_key = Object.values(snapshot.val())[1].apiKey
        api_id = Object.values(snapshot.val())[1].apiId
        syncIs = Object.values(snapshot.val())[1].syncIsOn
        console.log syncIs
        snapshot.forEach (childSnap) ->
          console.log childSnap

          if childSnap.val().Images != null
            logImageDataOnly(childSnap.val().Images)
            return

isset = (variable) ->
  if typeof variable != typeof undefined then true else false

logImageDataOnly = (Images) ->
  $.each Images, (timestamp, Image) ->
    tangRef = storageRef.child("#{Image.Path}")
    tangRef.getDownloadURL().then((url) ->
      if syncIs > 0
        console.log lastSyncDateIs
        console.log timestamp
        if timestamp > lastSyncDateIs
          updateSyncDate(iam_authenticated, user_email, timestamp, api_key, api_id, syncIs)
          sendItToSeaweedFS(url, mac_address, timestamp)
      else
        console.log "sync is off"
    ).catch (error) ->
      console.log error
      return

updateSyncDate = (auth, email, timestamp, api_key, api_id, syncIs) ->
  db_auth = auth.database().ref()
  obliged_email = "#{email}".replace(/\./g,'|')
  evercamRef = db_auth.child("#{obliged_email}")
  evercamRef.update
    evercam:
      apiKey: "#{api_key}"
      apiId: "#{api_id}"
      lastSyncDate: "#{timestamp}"
      syncIsOn: "#{syncIs}"
  console.log "done"

sendItToSeaweedFS = (url, mac_address, timestamp) ->
  data = {}
  data.url = "#{url}"
  data.dir_name = "#{mac_address}"
  data.timestamp = "#{timestamp}"

  onError = (response) ->
    console.log response

  onSuccess = (response) ->
    console.log response

  settings =
    error: onError
    success: onSuccess
    data: data
    cache: false
    dataType: "json"
    type: "GET"
    url: "/send_to_seaweedFS"

  sendAJAXRequest(settings)

onSignOut = ->
  $(".signout").on "click", ->
    firebase.auth().signOut().then(->
      # Sign-out successful.
      window.location = '/'
      console.log "signed out"
      return
    ).catch (error) ->
      # An error happened.
      return

onIntegrate = ->
  $("#integrate-me").on "click", ->
    $('.small.modal.integration').modal('show')

onSaveValues = ->
  $(".lets-integrate").on "click", ->
    api_key = $(".api_key").val()
    api_id = $(".api_id").val()
    $("#integrate-me").css("display", "none")
    $("#revoke-me").css("display", "block")
    addTable(firebase, user_email, api_key, api_id)
    startSync(firebase, user_email)

onRevoke = ->
  $(".yesrevoke").on "click", ->
    api_key = $(".api_key").val()
    api_id = $(".api_id").val()
    $("#integrate-me").css("display", "block")
    $("#revoke-me").css("display", "none")
    updateSyncDate(firebase, user_email, moment().unix(), api_key, api_id, "0")

onRevokeMe = ->
  $("#revoke-me").on "click", ->
    $('.small.modal.revoke').modal('show')  

addTable = (auth, email, api_key, api_id) ->
  db_auth = auth.database().ref()
  obliged_email = "#{email}".replace(/\./g,'|')
  evercamRef = db_auth.child("#{obliged_email}")
  evercamRef.update
    evercam:
      apiKey: "#{api_key}"
      apiId: "#{api_id}"
      syncIsOn: "1"
      lastSyncDate: '1293916756'

  console.log "done"

window.initializeIntegrations = ->
  moment.locale()
  startAuth()
  onLoad()
  onIntegrate()
  onSaveValues()
  onRevoke()
  onRevokeMe()
  onSignOut()
