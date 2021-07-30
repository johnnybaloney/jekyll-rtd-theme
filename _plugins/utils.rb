# Access variable [name] from Liquid.
def lookup(context, name)
  lookup = context
  name.split(".").each { |value| lookup = lookup[value] }
  lookup
end