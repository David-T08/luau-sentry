export type Options = {
	dsn: string
}

export type Exception = {

}

export type Breadcrumb = {
	type: string,
	category: string,

	message: string,
	level: string,

	timestamp: number,
	data: {[string]: any}
}

return {}