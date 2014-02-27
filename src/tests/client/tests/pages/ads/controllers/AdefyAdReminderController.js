describe("AdefyAdReminderController", function() {
  var scope = null;
  var httpBackend = null;

  beforeEach(function() {
    window.filepicker = { pickAndStore: function() {} };
    angular.mock.module("AdefyApp");

    angular.mock.inject(function($rootScope, $controller, $injector) {
      scope = $rootScope.$new();
      httpBackend = $injector.get("$httpBackend");

      $controller("AdefyAdReminderController", { $scope: scope });
    });
  });

  describe('Save method', function () {
    it('Exists', function () {
      scope.should.have.property("save");
    });

    it('Calls $save() on the ad model when called', function (done) {
      scope.ad = {
        id: 123,
        $save: function() { done(); }
      }

      scope.save();
    });
  });

  describe('Icon pick method', function () {
    it('Should spawn filepicker when called', function (done) {
      window.filepicker = { pickAndStore: function() { done(); } };
      scope.pickIcon();
    });
  });
});
