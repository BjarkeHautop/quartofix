// quartofix: minimal vanilla-JS behavior for Quarto tabsets and code
// annotations, standing in for the JS bundle (tabby.js, tippy.js) that
// pkgdown's minimal Quarto render omits.
(function () {
  "use strict";

  function activateTabset(tabset) {
    var links = tabset.querySelectorAll(".panel-tabset-tabby > li > a");
    if (links.length === 0) {
      // No reconstructed nav here - this is genuine Quarto/Bootstrap
      // markup (e.g. spliced in by quartofix2()), already self-sufficient
      // via pkgdown's bundled Bootstrap JS. Leave it alone.
      return;
    }
    var panes = tabset.querySelectorAll(".tab-content > div");

    function select(id) {
      links.forEach(function (a) {
        a.classList.toggle("quartofix-active", a.getAttribute("href") === "#" + id);
      });
      panes.forEach(function (div) {
        div.classList.toggle("quartofix-active", div.id === id);
      });
    }

    links.forEach(function (a) {
      a.addEventListener("click", function (event) {
        event.preventDefault();
        select(a.getAttribute("href").slice(1));
      });
    });

    var initial = tabset.querySelector("[data-tabby-default]") || links[0];
    if (initial) {
      select(initial.getAttribute("href").slice(1));
    }
  }

  function activateAnnotations(root) {
    var anchors = root.querySelectorAll(
      ".code-annotation-anchor, dt[data-target-annotation]"
    );

    anchors.forEach(function (el) {
      var cell = el.getAttribute("data-target-cell");
      var ann = el.getAttribute("data-target-annotation");
      if (!cell || !ann) return;

      var related = root.querySelectorAll(
        '[data-target-cell="' + cell + '"][data-target-annotation="' + ann + '"], ' +
        '#' + cell + "-" + ann
      );

      el.addEventListener("mouseenter", function () {
        related.forEach(function (r) {
          r.classList.add("quartofix-active");
        });
      });
      el.addEventListener("mouseleave", function () {
        related.forEach(function (r) {
          r.classList.remove("quartofix-active");
        });
      });
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    document.querySelectorAll(".panel-tabset").forEach(activateTabset);
    document.querySelectorAll(".cell").forEach(activateAnnotations);
  });
})();
