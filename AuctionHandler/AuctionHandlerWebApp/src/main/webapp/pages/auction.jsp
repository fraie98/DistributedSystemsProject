<%@ page import="dto.Auction" %>
<%@ page import="dto.AuctionState" %>
<%@ page import="java.util.List" %><%--
  Created by IntelliJ IDEA.
  User: gxhan
  Date: 19/01/2022
  Time: 16:57
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
  <title>Auction</title>
  <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T" crossorigin="anonymous">
  <script src="https://code.jquery.com/jquery-3.3.1.slim.min.js" integrity="sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo" crossorigin="anonymous"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js" integrity="sha384-UO2eT0CpHqdSJQ6hJty5KVphtPhzWj9WO1clHTMGa3JDZwrnQq4sF86dIHNDz0W1" crossorigin="anonymous"></script>
  <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js" integrity="sha384-JjSmVgyd0p3pXB1rRibZUAYoIIy6OrQ6VrjIEaFf/nJGzIxFDsf4x0xIM+B07jRM" crossorigin="anonymous"></script>
</head>
<body>
<%
  Auction auction = (Auction) request.getSession().getAttribute("currentAuction");
  AuctionState auctionState = (AuctionState) request.getSession().getAttribute("currentAuctionState");
%>
<div class="progress">
  <div class="progress-bar progress-bar-striped progress-bar-animated" role="progressbar"
       aria-valuenow="75" aria-valuemin="0" aria-valuemax="100" style="width: 75%"></div>
</div>

  <div class="container card my-4">
    <h1 class="d-flex justify-content-center m-3">
      Auction by: <%=auction.getUsername()%>
    </h1>
    <div class="d-flex justify-content-between p-3">

      <div class="d-flex flex-column justify-content-around" style="width: 30%;">
        <div class="d-flex justify-content-center">
          <h3><%=auction.getGoodName()%></h3>
        </div>
        <img class="card-img-top" src="<%=auction.getImageURL()%>"  onError="this.onerror=null;this.src='<%=request.getContextPath()%>/resources/default-placeholder.png';" alt="<%=auction.getGoodName()%> image">

        <h5 class="d-flex justify-content-center">
          <div id="totalTime" style="display: none;"> <%=auction.getDuration()%></div>
          <div id="remainingTime" style="display: none;"><%=auctionState.getRemainingTime()%></div>
          <div>Remaining Time: <b id="time_formatted"><%=auctionState.getFormattedTime()%></b></div>


        </h5>
        <form action="<%=request.getContextPath()%>/AuctionServlet" method="post"
              oninput='bid.setCustomValidity(parseInt(bid.value) < parseInt(minimum_bid.value) ? "Minimum offer must be " + minimum_bid.value + "€" : "")'>
          <div class="d-flex justify-content-between mb-3">

            <input type="number" name="minimum_bid" value="<%=auction.getStartingValue()%>" hidden>
            <div class="input-group">
              <div class="input-group-prepend">
                <span class="input-group-text">€</span>
              </div>
              <input type="number" class="form-control" name="bid" placeholder="Enter your bid" aria-describedby="bid">
              <div class="input-group-append">
                <span class="input-group-text">.00</span>
              </div>
            </div>
            <button type="submit" class="btn btn-primary mx-2 px-4"> BID </button>
          </div>
        </form>
      </div>
      <div class="d-flex flex-column justify-content-between">
        <div class="my-3">
          <h5 class="d-flex justify-content-center m-2">
            Joined Users
          </h5>
          <ul class="list-group overflow-auto" style="height: 15rem;">
            <li class="list-group-item active"><%=request.getSession().getAttribute("username")%></li>
            <%
              for(String participant: auctionState.getParticipants()){
            %>
            <li class="list-group-item"> <%=participant%></li>
            <%
              }
            %>
          </ul>
        </div>
        <div  class="my-3">
          <h5 class="d-flex justify-content-center m-2">
            Auction History
          </h5>
          <ul class="list-group overflow-auto" style="height: 15rem;">
            <%
              for(List<String> offer: auctionState.getOffers()){
            %>
              <li class="list-group-item"> <%=offer.get(0)%> bid <%=offer.get(1)%>€</li>
            <%
              }
            %>
          </ul>
        </div>
      </div>
    </div>

  </div>

<script>
  function startTimer(duration, display) {
    if (duration < 0)
      duration = 0;

    var timer = duration, hours, minutes, seconds;
    setInterval(function () {
      hours = parseInt(timer / 3600, 10);
      minutes = parseInt((timer / 60) % 60, 10);
      seconds = parseInt(timer % 60, 10);

      hours = hours < 10 ? "0" + hours : hours;
      minutes = minutes < 10 ? "0" + minutes : minutes;
      seconds = seconds < 10 ? "0" + seconds : seconds;

      display.textContent = hours + ":" + minutes + ":" + seconds;
      if(--timer < 0)
        timer=0;
    }, 1000);
  }

  window.onload = function () {
    var duration =  document.querySelector('#remainingTime').textContent;
    console.log(duration, typeof duration);
    display = document.querySelector('#time_formatted');
    startTimer(parseInt(duration)-1, display);
  };

</script>

</body>
</html>
