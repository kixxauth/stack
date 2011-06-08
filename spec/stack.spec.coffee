modstack = require '../stack'

describe 'Stack', ->

    it 'should serially run any number of functions', ->
        counter = 0

        f1 = (req, res, next) ->
            expect(counter).toBe 0
            counter += 1
            return next()

        f2 = (req, res, next) ->
            expect(counter).toBe 1
            counter += 1
            return next()

        f3 = (req, res, next) ->
            expect(counter).toBe 2
            return

        runit = modstack.stack(
            f1,
            f2,
            f3
        )

        runit()
        expect(counter).toBe 2
        return

    it 'should end with a 404 if no handler stops the chain', ->
        headers = {'Content-Type': 'text/plain'}

        res =
            writeHead: ->
            end: ->

        f1 = (req, res, next) ->
            return next()

        f2 = (req, res, next) ->
            return next()

        spyOn(res, 'writeHead')
        spyOn(res, 'end')

        runit = modstack.stack(f1, f2)
        runit(null, res)

        expect(res.writeHead).toHaveBeenCalledWith(404, headers)
        expect(res.end).toHaveBeenCalledWith('Not Found\n')
        return

    it 'should end with a 500 if a handler reports an error', ->
        lastCall = false
        headers = {'Content-Type': 'text/plain'}

        res =
            writeHead: ->
            end: ->

        f1 = (req, res, next) ->
            return next(new Error('foo'))

        f2 = (req, res, next) ->
            lastCall = true
            return

        spyOn(res, 'writeHead')
        spyOn(res, 'end')

        runit = modstack.stack(f1, f2)
        runit(null, res)

        expect(lastCall).toBe false
        expect(res.writeHead).toHaveBeenCalledWith(500, headers)
        expect(res.end).toHaveBeenCalledWith('foo')
        return

    it 'should maintain the state of the `this` object', ->
        count = 0
        f1 = (req, res, next) ->
            expect(@.process).not.toBeDefined()
            @.one = 1
            count += 1
            return next()

        f2 = (req, res, next) ->
            expect(@.one).toBe 1
            @.one= 'one'
            count += 1
            return next()

        f3 = (req, res, next) ->
            expect(@.one).toBe 'one'
            count += 1

        runit = modstack.stack(f1, f2, f3)
        runit()

        expect(count).toBe 3
        return
