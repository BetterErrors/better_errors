// Test js loaded
if (window.jQuery) {

    (function ($) {

        //  Toggle states of functions when clicked

        $.fn.toggleClick = function () {
            var functions = arguments,
                iteration = 0
            return this.click(function () {
                functions[iteration].apply(this, arguments)
                iteration = (iteration + 1) % functions.length
            })
        }

        //  Listen to jquery Ajax error event
        $(document)
            .ajaxError(function () {
                // Check and load better_errors iframe
                if ($("#better_errors").length == 0) {
                    $('body').append(
                        '<div id="better_errors">' +
                        '<span>' +
                        'The request had an error when submitted via ajax.<br>' +
                        'Note:Your page has not been reloaded.<br>' +
                        'Close this to return to your page.<br>' +
                        '</span>' +
                        '<a href="javascript:void(0);" class="button_be remove_be" title="Close better error"></a>' +
                        '<a href="javascript:void(0);" class="button_be fade_be" title="Fade better error"></a>' +
                        '<a href="javascript:void(0);" class="button_be minimize_be" title="Minimize better error"></a>' +
                        '<iframe src="/__better_errors" ></iframe></div>'
                    )

                    // Reference Iframe
                    var BEIframe = $("#better_errors iframe");

                    // Remove better error iframe with its parent div
                    $("#better_errors .remove_be").click(
                        function () {
                            $(this).parent().remove();
                        });
                    // Fade the iframe so that we could see better errors iframe and the actual page in the same view
                    $("#better_errors .fade_be").toggleClick(
                        function () {
                            BEIframe.css('opacity', 0.17);
                        },
                        function () {
                            BEIframe.css('opacity', 1);
                        });
                    // Minimize better errors iframe
                    $("#better_errors .minimize_be").toggleClick(
                        function () {
                            $("#better_errors").addClass('minimize');
                        },
                        function () {
                            $("#better_errors").removeClass('minimize');
                        });
                } else {
                    // Maximize the iframe if minimized previously
                    $("#better_errors").removeClass('minimize');
                    //  Reload the iframe if already opened
                    $("#better_errors iframe")[0].contentDocument.location.reload(true);
                }
            });

    }(jQuery));

} else {
    if (window.console)
        console.log("better errors ajax needs jQuery to be loaded!!")
}