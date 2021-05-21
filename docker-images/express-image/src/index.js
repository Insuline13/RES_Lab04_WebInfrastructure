var Chance = require('chance');
var chance = new Chance();

var express = require('express');
var app = express();

app.get('/', function(request, response) {
   response.send(generateAnimals());
});

app.listen(3000, function () {
   console.log('Accepting HTTP on port 3000!');
});

function generateAnimals() {
   var numberOfAnimals = chance.integer({
      min: 1,
      max: 5
   });

   console.log(numberOfAnimals);

   var animals = [];
   for (var i = 0; i < numberOfAnimals; i++) {
      var gender = chance.gender();
      var birthYear = chance.year({min: 2000,max: 2020});

      animals.push({
         animal: chance.animal(),
         name: chance.first({gender: gender}),
         gender: gender,
         birthday: chance.birthday({year: birthYear})
      });
   };

   console.log(animals);
   return animals;
}
