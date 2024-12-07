local envelopeEventTypes = {
	event = {event_id = { required = true, value = "" }}
}

type Level = 'fatal' | 'error' | 'warning' | 'info' | 'debug'

export type Options = {
	dsn: string,

	-- The /store endpoint is marked as deprecated, but the use of /envelope requires you to use a Relay (https://docs.sentry.io/product/relay/)
	-- However, relays must be self hosted.
	-- Set this to true if your DSN points to a relay that supports envelopes, otherwise set to false/nil
	supportsEnvelopes: boolean?,
	-- 0-1, Determines how many events get sent (0.5 -> 50%)
	sampleRate: number?,

	integrations: any?,
	defaultIntegrations: any?,

	maxBreadcrumbs: number?,

	-- Allows the capturing of environment variables using getfenv()
	-- Only use this if needed, as getfenv() disables Luau's performance optimizations
	captureEnvironment: boolean?
}

export type Breadcrumb = {
	type: string,

	message: string,
	level: string,

	timestamp: number,
	data: {[string]: any}
}

-- export type Envelope = {
-- 	Items: {Item}
-- }

export type Exception = {
	
}

export type Event = {
	event_id: string,
	timestamp: number | string,
	platform: 'other',

	level: Level,
	environment: 'production' | 'development',
	logger: string | 'server' | 'client',

	extra: {[string]: any}?,
	tags: {[string]: any}?,
}

export type _sentry_impl = {
	__index: _sentry_impl,

	init: (options: Options, name: string) -> Sentry,
	get: (name: string) -> Sentry,

	globalHub: (self: Sentry) -> Hub,
	currentHub: (self: Sentry) -> Hub,
	transport: (self: Sentry) -> Transporter,

	captureMessage: (self: Sentry, message: string) -> string,
	captureEvent: (self: Sentry, event: Event) -> string,
	captureException: (self: Sentry, exception: Exception) -> string,

	configureScope: (self: Sentry, (scope: Scope) -> ()) -> (),

	lastEventId: (self: Sentry) -> string?
}

export type Sentry = typeof(setmetatable({} :: {
	-- Global hub which all threads inherit from
	_main_hub: Hub,
	-- Each thread has its own hub
	_hubs: {[string]: Hub},

	transport: Transporter
}, {} :: _sentry_impl))

export type _hub_impl = {
	__index: _hub_impl,
	__tostring: (self: Hub) -> string,

	new: (transport: Transporter, scope: Scope?) -> Hub,
	clone: (self: Hub) -> Hub,

	-- Returns a function that pops the scope, to help prevent stack underflow
	pushScope: (self: Hub) -> () -> (),

	captureEvent: (self: Hub, event: Event) -> string,
	captureException: (self: Hub, exception: Exception) -> string,
	captureMessage: (self: Hub, message: string) -> string,
}

export type Hub = typeof(setmetatable({} :: {
	transport: Transporter,

	stack: {Scope},
	_lastEventId: string?,
}, {} :: _hub_impl))

export type _scope_impl = {
	__index: _scope_impl,

	new: () -> Scope,
	clone: (self: Scope) -> Scope,

	setUser: (self: Scope, player: Player) -> (),

	setExtra: (self: Scope, key: string, value: any) -> (),
	setExtras: (self: Scope, extras: {[string]: any}) -> (),

	setTag: (self: Scope, tag: string, value: any) -> (),
	setTags: (self: Scope, tags: {[string]: any}) -> (),

	-- Will not implement for now, still trying to figure out what this context is
	-- _setContext: (self: Scope) -> (),
	-- _setFingerprint: (self: Scope) -> (),

	setLevel: (self: Scope, level: Level) -> (),
	setTransaction: (self: Scope, name: string) -> (),
	
	clear: (self: Scope) -> (),
	clearBreadcrumbs: (self: Scope) -> (),

	addBreadcrumb: (self: Scope, breadcrumb: Breadcrumb) -> (),

	applyToEvent: (self: Scope, event: Event) -> (),
}

export type Scope = typeof(setmetatable({} :: {
	extras: {[string]: any},
	tags: {[string]: any},

	user: {
		id: string,
		username: string,
		locale: string
	}?,

	transaction: string?,

	level: Level,
	breadcrumbs: {Breadcrumb},
	context: {[string]: any},
}, {} :: _scope_impl))

export type _transporter_impl = {
	__index: _transporter_impl,

	init: (options: Options) -> Transporter
}

export type DSNComponents = {
	protocol: string,
	publicKey: string, 
	url: string,
	projectId: string
}

export type Transporter = typeof(setmetatable({} :: {
	dsn: DSNComponents,
	basePath: string,

	envelopeSupport: boolean,
	lastRequest: number,
	retry_after: number
}, {} :: _transporter_impl))

return {}
