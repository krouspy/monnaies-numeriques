import React from 'react';

const style = {
  display: 'flex',
  flexDirection: 'column',
  justifyContent: 'center',
  alignItems: 'center',
};

export default () => {
  return (
    <div style={style}>
      <h2>You can pay me on-chain</h2>
      <form method="POST" action="http://localhost:8080/api/v1/invoices">
        <input type="hidden" name="storeId" value="ArHTqAhGinUKeoGBPJfaX2EGqhNeFnfaGoRk6qJKFBS5" />
        <input type="hidden" name="price" value="2" />
        <input type="hidden" name="currency" value="USD" />
        <input type="image" src="http://localhost:8080/img/paybutton/pay.svg"></input>
      </form>
      <h2>Or with Lightning for faster transactions</h2>
    </div>
  );
};
