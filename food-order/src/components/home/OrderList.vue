<template>
  <div>
    <div class="row mx-auto">
      <div id="clockdiv" style="margin: auto" v-show="show_count_down">
        <div>
          <span class="minutes"></span>
          <div class="smalltext">Minutes</div>
        </div>
        <div>
          <span class="seconds"></span>
          <div class="smalltext">Seconds</div>
        </div>
      </div>
      <div class="form-wrap">
        <div class="tab">

          <div class="tab-content">
            <div class="tab-content-inner active" data-content="signup">
              <h3 class="cursive-font" v-show="!$store.state.finished_order">Ordered Foods</h3>
              <h3 class="cursive-font text-danger" v-show="$store.state.finished_order">Order Time Finished</h3>
              <hr>
              <div class="row">
                <div class="col-md-12">
                  <div class="row">
                    <div class="col-md-8">
                      <a href="#">Name Foods</a>
                    </div>
                    <div class="col-md-3">
                      <a href="#">Count</a>
                    </div>
                  </div>
                  <ul class="food-name">
                    <li class="row" v-for="food in current_order.orderList">
                      <div class="col-md-7 amout">{{food.name}}</div>
                      <div class="col-md-5">{{food.number}} x {{formatCurrency(food.default_price)}}$</div>
                    </li>
                  </ul>
                </div>
              </div>
              <hr>
              <div class="row">
                <div class="col-md-8">
                  <a href="#">Total:</a>
                </div>
                <div class="col-md-3">
                  <a href="#">{{formatCurrency(total_price)}}$</a>
                </div>
              </div>
              <div class="form-group">
<!--                <button type="button" class="btn btn-1" @click="showOrderDetail" data-toggle="modal" data-target="#orderDetail"><span class="glyphicon glyphicon-heart"></span>ORDER</button>-->
                <button type="button" class="btn btn-1" @click="showOrderDetail" data-toggle="modal" data-target="#order_detail" :disabled="$store.state.finished_order"><span class="glyphicon glyphicon-edit"></span>EDIT ORDER</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>
<script>
  import {post} from '../../helper/request'
  export default {
    name: 'orderList',

    components: {
    },

    data() {
      let current_order = this.$store.state.orderList.filter(o => o.user_id === this.$store.state.auth.user.id)
      return {
        current_user: this.$store.state.auth.user,
        orderList: this.$store.state.orderList,
        current_order: current_order.length ? current_order[0] : {orderList: []},
        show_order_detail: false,
        start_time: '',
        end_time: '',
        is_show_count_down: false,
      }
    },

    computed: {
      'total_price': function() {
        let total = 0
        this.current_order.orderList.forEach((o) => {
          total += (o.number * o.default_price)
        })
        return total
      },

      'show_count_down': function() {
        if(this.start_time) {
          let t = Date.parse(this.start_time) - Date.parse(new Date());
          let t1 = Date.parse(this.end_time) - Date.parse(new Date());
          return t <= 0 && t1 >= 0
        }
        if(this.end_time) {

        }
        return false
      }
    },

    watch: {
      'orderList': function () {
        let current_order = this.$store.state.orderList.filter(o => o.user_id === this.$store.state.auth.user.id)
        this.current_order = current_order.length ? current_order[0] : {orderList: []}
      },

      '$store.state.daily': function() {
        if(this.$store.state.daily) {
          this.start_time = this.$store.state.daily.start_time_order
          this.end_time = this.$store.state.daily.end_time_order
        }
      },

      'show_count_down': function() {
        if(this.show_count_down) {
          this.$store.state.finished_order = false
        }
        else {
          this.$store.state.finished_order = true
        }
      },
      'end_time': function() {
        if (this.end_time) {
          this.createClock()
        }
      }
    },

    mounted() {
    },

    methods: {
      getTimeRemaining(endtime) {
        var t = Date.parse(endtime) - Date.parse(new Date());
        var seconds = Math.floor((t / 1000) % 60);
        var minutes = Math.floor((t / (1000 * 60)));
        return {
          'total': t,
          'minutes': minutes,
          'seconds': seconds
        };
      },

      initializeClock(id, endtime) {
        var clock = document.getElementById(id);
        var minutesSpan = clock.querySelector('.minutes');
        var secondsSpan = clock.querySelector('.seconds');

        let updateClock = () => {
          var t = this.getTimeRemaining(endtime);
          minutesSpan.innerHTML = (t.minutes);
          secondsSpan.innerHTML = ('0' + t.seconds).slice(-2);
          if (t.total <= 0) {
            this.$store.state.finished_order = true
            this.clearAllOrdered()
            clearInterval(timeinterval);
            this.showNoty()
          }
        }

        updateClock();
        var timeinterval = setInterval(updateClock, 1000);
      },

      createClock() {
        var deadline = new Date(Date.parse(this.end_time))
        this.initializeClock('clockdiv', deadline);
      },
      submitOrder() {
        let url = process.env.api_host + '/submit-order'
        let payload = {
          orders: this.current_order.orderList
        }
        post(url, payload)
          .then(res => {
            console.log('res: ', res)
            let index = this.$store.state.orderList.indexOf(this.current_order)
            if(index > 0) {
              this.$store.state.orderList.splice(index, 1)
              window.localStorage.setItem('orderList', JSON.stringify(this.$store.state.orderList))
              this.$notify({
                group: 'foo',
                type: 'success',
                title: 'Order Successfully',
                text: 'Thanks for your order! Let it be!',
                duration: 25000,
                speed: 2000
              });
            }
          })
      },

      clearAllOrdered() {
        this.$store.state.orderList = []
        window.localStorage.setItem('orderList', JSON.stringify(this.$store.state.orderList))
        this.current_order.orderList = []
      },

      showNoty () {
        this.$notify({
          group: 'foo',
          type: 'warn',
          title: "Finish Order Time!",
          text: 'Order time was finished! Thanks for your order! Let it be!',
          duration: 25000,
          speed: 2000
        });
      },

      showOrderDetail() {
        this.$store.state.show_order_detail = true
      }
    }
  }

</script>
