if typeof process is 'object' and process.title is 'node'
  chai = require 'chai' unless chai
  aport = require '../src/lib/ArrayPort.coffee'
  socket = require '../src/lib/InternalSocket.coffee'
else
  aport = require 'noflo/src/lib/ArrayPort.js'
  socket = require 'noflo/src/lib/InternalSocket.js'

describe 'Untyped ArrayPort instance', ->
  it 'should be of type "all"', ->
    p = new aport.ArrayPort
    chai.expect(p.type).to.equal 'all'

describe 'ArrayPort instance', ->
  p = null
  it 'should retain the given type', ->
    p = new aport.ArrayPort 'string'
    chai.expect(p.type).to.equal 'string'

  describe 'without attached socket', ->
    it 'should not be attached initially', ->
      chai.expect(p.isAttached()).to.equal false
    it 'should not be connected initially', ->
      chai.expect(p.isConnected()).to.equal false
    it 'should not contain a socket initially', ->
      chai.expect(p.sockets.length).to.equal 0
    it 'should not allow connecting', ->
      chai.expect(-> p.connect()).to.throw Error
    it 'should not allow beginning groups', ->
      chai.expect(-> p.beginGroup('Foo')).to.throw Error
    it 'should not allow sending data', ->
      chai.expect(-> p.send('Foo')).to.throw Error
    it 'should not allow ending groups', ->
      chai.expect(-> p.endGroup()).to.throw Error
    it 'should not allow disconnecting', ->
      chai.expect(-> p.disconnect()).to.throw Error

  describe 'with attached socket', ->
    s = new socket.InternalSocket
    it 'should emit an event', (done) ->
      p.once 'attach', (sock) ->
        chai.expect(sock).to.equal s
        done()
      p.attach s
    it 'should not be marked as attached', ->
      chai.expect(p.isAttached()).to.equal false
    it 'should not be connected initially', ->
      chai.expect(p.isConnected()).to.equal false
    it 'should have a reference to the socket', ->
      chai.expect(p.sockets.indexOf(s)).to.equal 0
    it 'should allow other sockets to be attached', ->
      s2 = new socket.InternalSocket
      p.attach s2
      chai.expect(p.sockets.length).to.equal 2
      p.detach s2
      chai.expect(p.sockets.length).to.equal 1

    it 'should emit an event on detaching', (done) ->
      p.once 'detach', (sock) ->
        chai.expect(sock).to.equal s
        done()
      p.detach s
    it 'should not be attached any longer', ->
      chai.expect(p.isAttached()).to.equal false
    it 'should not contain the removed socket any longer', ->
      chai.expect(p.sockets.length).to.equal 0

describe 'Input ArrayPort', ->
  p = new aport.ArrayPort
  s = new socket.InternalSocket
  p.attach s
  it 'should emit connection events', (done) ->
    p.once 'connect', (sock, id) ->
      chai.expect(sock).to.equal s
      chai.expect(id).to.equal 0
      done()
    s.connect()
  it 'should be connected after that', ->
    chai.expect(p.isConnected()).to.equal true
  it 'should emit begin group events', (done) ->
    p.once 'begingroup', (group, id) ->
      chai.expect(group).to.equal 'Foo'
      chai.expect(id).to.equal 0
      done()
    s.beginGroup 'Foo'
  it 'should emit data events', (done) ->
    p.once 'data', (data, id) ->
      chai.expect(data).to.equal 'Bar'
      chai.expect(id).to.equal 0
      done()
    s.send 'Bar'
  it 'should emit end group events', (done) ->
    p.once 'endgroup', (group, id) ->
      chai.expect(group).to.equal 'Foo'
      chai.expect(id).to.equal 0
      done()
    s.endGroup()
  it 'should emit disconnection events', (done) ->
    p.once 'disconnect', (sock, id) ->
      chai.expect(sock).to.equal s
      chai.expect(id).to.equal 0
      done()
    s.disconnect()
  it 'should not be connected after that', ->
    chai.expect(p.isConnected()).to.equal false
  it 'should connect automatically when sending', (done) ->
    p.once 'connect', (sock, id) ->
      chai.expect(sock).to.equal s
      chai.expect(id).to.equal 0
      chai.expect(p.isConnected()).to.equal true
      p.once 'data', (data, id) ->
        chai.expect(data).to.equal 'Baz'
        chai.expect(id).to.equal 0
        done()
    s.send 'Baz'

describe 'Output ArrayPort', ->
  p = new aport.ArrayPort
  s = new socket.InternalSocket
  p.attach s
  it 'should connect the socket', (done) ->
    s.once 'connect', ->
      chai.expect(p.isConnected()).to.equal true
      done()
    p.connect()
  it 'should begin groups on the socket', (done) ->
    s.once 'begingroup', (group) ->
      chai.expect(group).to.equal 'Baz'
      done()
    p.beginGroup 'Baz'
  it 'should send data to the socket', (done) ->
    s.once 'data', (data) ->
      chai.expect(data).to.equal 'Foo'
      done()
    p.send 'Foo'
  it 'should end groups on the socket', (done) ->
    s.once 'endgroup', (group) ->
      chai.expect(group).to.equal 'Baz'
      done()
    p.endGroup()
  it 'should disconnect the socket', (done) ->
    s.once 'disconnect', ->
      chai.expect(p.isConnected()).to.equal false
      done()
    p.disconnect()
  it 'should connect automatically when sending', (done) ->
    s.once 'connect', ->
      chai.expect(p.isConnected()).to.equal true
      s.once 'data', (data) ->
        chai.expect(data).to.equal 'Bar'
        done()
    p.send 'Bar'
