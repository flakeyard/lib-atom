# The error for an upstream flake that the consumer locks a second time
# (FY-0017), or null. Only store paths are compared; nothing is imported from
# the consumer's input.
{
  # The atom, such as atom-shell, as the message names it.
  atom,
  # The atom's inputs.
  own,
  # The consumer's inputs, the module argument inputs of flake-parts.
  consumer,
}:
# The name of the input in the atom and in the consumer.
name:
if !(consumer ? ${name}) || consumer.${name}.outPath == own.${name}.outPath then
  null
else
  ''
    ${atom}: input '${name}' is locked twice; add to input ${atom}:
      inputs.${name}.follows = "${name}";''
