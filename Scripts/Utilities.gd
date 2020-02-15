# Randomize a value by a certain percentage.
# Returns value +- percentage * value.
static func RandomizeValue(value, percentage):
	var fraction = percentage / 100;
	return value * rand_range(1 - fraction,1 + fraction)

