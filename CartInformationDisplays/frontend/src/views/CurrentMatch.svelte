<div class="bg">
    <div class="padding">
        <div class="alliance">
            <p class="redAlliance allianceNumbers">1234</p>
            <p class="redAlliance allianceNumbers">5678</p>
            <p class="redAlliance allianceNumbers">9012</p>
        </div>
        <div class="divider"></div>
        <div class="alliance">
            <p class="blueAlliance allianceNumbers">1234</p>
            <p class="blueAlliance allianceNumbers">5678</p>
            <p class="blueAlliance allianceNumbers">9012</p>
        </div>
    </div>
</div>

<style>
.bg {
    background-color: black;
    width: 100%;
    height: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
}

.padding {
    width: 80%;
    height: 30%;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    align-items: center;
}

.alliance {
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    width: 80%;
}

.divider {
    width: 100%;
    height: 0.2vw;
    background-color: rgba(255, 255, 255, 0.5);
    border-radius: 0.1vw;
}

.allianceNumbers {
    font-size: 2vw;
    font-weight: bold;
    text-align: center;
}

.redAlliance {
    color: #ED1C24;
}

.blueAlliance {
    color: #0066B3;
}
</style>