$(function() {
  console.log("Loading animals");

  function loadAnimals() {
    $.getJSON( "/api/animals/", function(animals) {
      console.log(animals);
      $(".spawn-animal").text(animals[0].name + " the " + animals[0].animal);
    });
  };

  loadAnimals();
  setInterval(loadAnimals, 2000);
});
