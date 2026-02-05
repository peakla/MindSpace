(function() {
    'use strict';
    
    const warningMessage = 'Developer tools are disabled on this site for security purposes.';
    
    document.addEventListener('contextmenu', function(e) {
        e.preventDefault();
        return false;
    });
    
    document.addEventListener('keydown', function(e) {
        if (e.key === 'F12') {
            e.preventDefault();
            return false;
        }
        
        if (e.ctrlKey && e.shiftKey && (e.key === 'I' || e.key === 'i')) {
            e.preventDefault();
            return false;
        }
        
        if (e.ctrlKey && e.shiftKey && (e.key === 'J' || e.key === 'j')) {
            e.preventDefault();
            return false;
        }
        
        if (e.ctrlKey && e.shiftKey && (e.key === 'C' || e.key === 'c')) {
            e.preventDefault();
            return false;
        }
        
        if (e.ctrlKey && (e.key === 'U' || e.key === 'u')) {
            e.preventDefault();
            return false;
        }
        
        if (e.ctrlKey && (e.key === 'S' || e.key === 's')) {
            e.preventDefault();
            return false;
        }
    });
    
    let devToolsOpen = false;
    const threshold = 160;
    
    function checkDevTools() {
        const widthThreshold = window.outerWidth - window.innerWidth > threshold;
        const heightThreshold = window.outerHeight - window.innerHeight > threshold;
        
        if (widthThreshold || heightThreshold) {
            if (!devToolsOpen) {
                devToolsOpen = true;
                showWarningOverlay();
            }
        } else {
            if (devToolsOpen) {
                devToolsOpen = false;
                hideWarningOverlay();
            }
        }
    }
    
    let warningOverlay = null;
    
    function showWarningOverlay() {
        if (warningOverlay) return;
        
        warningOverlay = document.createElement('div');
        warningOverlay.id = 'security-warning-overlay';
        warningOverlay.innerHTML = `
            <div style="
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.95);
                z-index: 999999;
                display: flex;
                align-items: center;
                justify-content: center;
                flex-direction: column;
                color: white;
                font-family: 'Poppins', sans-serif;
            ">
                <div style="
                    font-size: 48px;
                    margin-bottom: 20px;
                ">&#128274;</div>
                <h2 style="
                    font-size: 24px;
                    margin-bottom: 10px;
                    text-align: center;
                ">Developer Tools Detected</h2>
                <p style="
                    font-size: 16px;
                    text-align: center;
                    max-width: 400px;
                    opacity: 0.8;
                ">Please close developer tools to continue viewing this site.</p>
            </div>
        `;
        document.body.appendChild(warningOverlay);
    }
    
    function hideWarningOverlay() {
        if (warningOverlay) {
            warningOverlay.remove();
            warningOverlay = null;
        }
    }
    
    setInterval(checkDevTools, 1000);
    
    (function() {
        const originalLog = console.log;
        const originalWarn = console.warn;
        const originalError = console.error;
        const originalInfo = console.info;
        
        console.log = function() {};
        console.warn = function() {};
        console.error = function() {};
        console.info = function() {};
        console.debug = function() {};
        console.table = function() {};
        console.dir = function() {};
        console.dirxml = function() {};
        console.group = function() {};
        console.groupCollapsed = function() {};
        console.groupEnd = function() {};
        console.time = function() {};
        console.timeEnd = function() {};
        console.timeLog = function() {};
        console.trace = function() {};
        console.assert = function() {};
        console.count = function() {};
        console.countReset = function() {};
        console.profile = function() {};
        console.profileEnd = function() {};
        
        try {
            console.clear();
        } catch(e) {}
    })();
    
    (function() {
        function detectDebugger() {
            const start = performance.now();
            debugger;
            const end = performance.now();
            if (end - start > 100) {
                showWarningOverlay();
            }
        }
    })();
    
})();
