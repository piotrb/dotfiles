import RandomGenerator, { RandomSeed } from 'random-seed'

import _ from 'lodash';

const seed = process.argv[2];

const defaultAdjectives = [
  'aged', 'ancient', 'autumn', 'billowing', 'bitter', 'black', 'blue', 'bold',
  'broad', 'broken', 'calm', 'cold', 'cool', 'crimson', 'curly', 'damp',
  'dark', 'dawn', 'delicate', 'divine', 'dry', 'empty', 'falling', 'fancy',
  'flat', 'floral', 'fragrant', 'frosty', 'gentle', 'green', 'hidden', 'holy',
  'icy', 'jolly', 'late', 'lingering', 'little', 'lively', 'long', 'lucky',
  'misty', 'morning', 'muddy', 'mute', 'nameless', 'noisy', 'odd', 'old',
  'orange', 'patient', 'plain', 'polished', 'proud', 'purple', 'quiet', 'rapid',
  'raspy', 'red', 'restless', 'rough', 'round', 'royal', 'shiny', 'shrill',
  'shy', 'silent', 'small', 'snowy', 'soft', 'solitary', 'sparkling', 'spring',
  'square', 'steep', 'still', 'summer', 'super', 'sweet', 'throbbing', 'tight',
  'tiny', 'twilight', 'wandering', 'weathered', 'white', 'wild', 'winter', 'wispy',
  'withered', 'yellow', 'young'
]

const defaultNouns = [
  'art', 'band', 'bar', 'base', 'bird', 'block', 'boat', 'bonus',
  'bread', 'breeze', 'brook', 'bush', 'butterfly', 'cake', 'cell', 'cherry',
  'cloud', 'credit', 'darkness', 'dawn', 'dew', 'disk', 'dream', 'dust',
  'feather', 'field', 'fire', 'firefly', 'flower', 'fog', 'forest', 'frog',
  'frost', 'glade', 'glitter', 'grass', 'hall', 'hat', 'haze', 'heart',
  'hill', 'king', 'lab', 'lake', 'leaf', 'limit', 'math', 'meadow',
  'mode', 'moon', 'morning', 'mountain', 'mouse', 'mud', 'night', 'paper',
  'pine', 'poetry', 'pond', 'queen', 'rain', 'recipe', 'resonance', 'rice',
  'river', 'salad', 'scene', 'sea', 'shadow', 'shape', 'silence', 'sky',
  'smoke', 'snow', 'snowflake', 'sound', 'star', 'sun', 'sun', 'sunset',
  'surf', 'term', 'thunder', 'tooth', 'tree', 'truth', 'union', 'unit',
  'violet', 'voice', 'water', 'waterfall', 'wave', 'wildflower', 'wind', 'wood'
]

const versionParts = process.argv[2].split(".")

function randomElement(random: RandomSeed, array: Array<string>): string {
  return array[random(array.length)]
}

const words = versionParts.map((versionPart, index) => {
  const random = RandomGenerator.create(versionPart)
  if(index === 0) {
    // first is always adjective
    return randomElement(random, defaultAdjectives)
  } else {
    // everything else is noun
    return randomElement(random, defaultNouns)
  }
})

const name = words.map((w) => _.capitalize(w)).join(' ')

console.info(name);
