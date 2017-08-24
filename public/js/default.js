$(".alert-dismissible").fadeTo(2000, 500).slideUp(500, function () {
    $(".alert-dismissible").alert('close');
});

/**
 * Show Instant Message.
 *
 * @param {string} type - success|info|warning|danger
 * @param {string} message
 */
function showAlert(type, message) {
    var alertDiv = $(
        '<div class="alert alert-' + type + ' alert-dismissible">\n' +
        '    <button type="button" class="close" data-dismiss="alert">&times;</button>' + message + '\n' +
        '</div>\n'
        ),
        delayDuration = 2000,
        slideUpDuration = 500;

    alertDiv.delay(delayDuration).slideUp(slideUpDuration);

    $('.flashes').append(alertDiv);
}


/**
 * showModal
 *
 * @param {string} modalContent
 * @param {object} options
 * @param {string} modalDivId
 */
function showModal(modalContent, options, modalDivId) {
    var modalDiv,
        modalSize = '';

    modalDivId = modalDivId || 'kollus-modal';

    options = options || {};

    if ('modalSize' in options) {
        modalSize = ' ' + options.modalSize;
    }

    modalDiv = $('#' + modalDivId);
    if (!modalDiv.length) {
        modalDiv = $(
            '<div class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">' +
            '    <div class="modal-dialog modal-lg">' +
            '        <div class="modal-content"></div>' +
            '    </div>' +
            '</div>'
        );

        modalDiv.attr('id', modalDivId);
        modalDiv.on('hidden.bs.modal', function(e) {
            // when iframe closed at IE, video in video does not stop.
            // so, iframe's src must set 'null'
            $('#' + modalDivId + ' .modal-body iframe').attr('src', null);
            $('#' + modalDivId + ' .modal-body').html('');
        });
        $('body').append(modalDiv);

        modalDiv.modal(options);
    }

    modalDiv.find('.modal-content').html(modalContent);
    modalDiv.modal('show');
}

/**
 * hideModal
 *
 * @param {string} modalDivId
 */
function hideModal(modalDivId) {
    var modalDiv;

    modalDivId = modalDivId || 'kollus-modal';

    modalDiv = $('#' + modalDivId);
    if (modalDiv.length) {
        modalDiv.modal('hide');
    }
}

$(document).on('change', 'select[data-action=channel-selector]', function(e) {
    e.preventDefault();
    e.stopPropagation();

    $(location).attr('href', '/channel/' + $(this).val());
});

$(document).on('click', 'button[data-action=modal-play-video]', function(e) {
    e.preventDefault();
    e.stopPropagation();

    var self = this,
        channelKey = $(self).attr('data-channel-key'),
        uploadFileKey = $(self).attr('data-upload-file-key'),
        mediaContent;

    $.post('/auth/web-token-url/' + channelKey + '/' + uploadFileKey, function (data) {
        mediaContent = $(
            '<div class="modal-header">\n' +
            '    <button type="button" class="close" data-dismiss="modal">&times;</button>\n' +
            '    <h4 class="modal-title">' + data.title + '</h4>\n' +
            '</div>\n'+
            '<div class="modal-body">\n' +
            '    <div class="embed-responsive embed-responsive-16by9">\n' +
            '        <iframe src="' + data.web_token_url + '" class="embed-responsive-item" allowfullscreen></iframe>\n' +
            '    </div>\n' +
            '</div>\n' +
            '<div class="modal-footer">\n' +
            '    <button type="button" class="btn btn-default" data-dismiss="modal"><span class="fa fa-times"></span> Close</button>\n' +
            '</div>'
        );

        showModal(mediaContent)
    });
});